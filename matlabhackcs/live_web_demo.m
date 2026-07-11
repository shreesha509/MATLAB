function live_web_demo()
% =========================================================================
% live_web_demo.m
% Purpose : Real-time suspension simulation that streams telemetry to a
%           web dashboard via UDP. Receives slider overrides from the web.
% Note    : Uses Java UDP to avoid Instrument Control Toolbox requirement.
% Usage   : >> live_web_demo
% =========================================================================

    %% --- Configuration ---------------------------------------------------
    DT         = 0.01;          % simulation timestep (s)
    T_END      = 10.0;          % total simulation window (s)
    BUMP_TIME  = 2.0;           % default bump onset (s)
    FRAME_MS   = 30;            % target ~33 fps to web
    LOOP_PAUSE = FRAME_MS/1000;
    STEPS_PER_FRAME = max(1, round(LOOP_PAUSE / DT));

    % PID gains (fixed, matching sim_pid_reactive.m)
    Kp = 20;  Ki = 10;  Kd = 5;

    % Plant: G(s) = 1/(s^2 + 3s + 2)
    A_plant = [0 1; -2 -3];
    B_plant = [0; 1];

    %% --- Slider-controlled parameters (defaults) ------------------------
    bump_height = 1.0;          % amplitude of road bump
    preview_ms  = 200;          % AI preview horizon in ms

    %% --- UDP Setup (Using Java to bypass toolbox requirement) ------------
    import java.net.DatagramSocket
    import java.net.DatagramPacket
    import java.net.InetAddress
    import java.lang.String

    try
        sendSocket = DatagramSocket();
        recvSocket = DatagramSocket(5005);
        recvSocket.setSoTimeout(1); % 1 ms timeout for non-blocking receive
        targetAddress = InetAddress.getByName('127.0.0.1');
        targetPort = 5000;
    catch e
        error('Failed to bind UDP sockets. Ensure port 5005 is not already in use.');
    end
    
    cleanObj = onCleanup(@() cleanup(sendSocket, recvSocket));

    fprintf('\n=========================================================\n');
    fprintf('  LIVE WEB DEMO — Streaming to UDP :5000\n');
    fprintf('  Listening for slider overrides on UDP :5005\n');
    fprintf('  Press Ctrl+C to stop.\n');
    fprintf('=========================================================\n\n');

    %% --- Main Loop (repeats the 0–10s window) ----------------------------
    while true
        % Reset states for each simulation pass
        x_pas = [0;0];   % passive plant state
        x_pid = [0;0];   % PID plant state
        x_ai  = [0;0];   % AI plant state
        int_pid = 0;      % PID integrator
        int_ai  = 0;      % AI integrator

        t = 0;
        step = 0;

        while t <= T_END
            tic;

            % --- Read slider overrides from web ---------------------------
            try
                % Attempt to read multiple packets to drain the buffer
                while true
                    recvData = zeros(1, 1024, 'int8');
                    recvPacket = DatagramPacket(recvData, length(recvData));
                    recvSocket.receive(recvPacket);
                    
                    rawBytes = recvPacket.getData();
                    rawStr = char(rawBytes(1:recvPacket.getLength())');
                    
                    msg = jsondecode(rawStr);
                    if isfield(msg,'bump_height'), bump_height = msg.bump_height; end
                    if isfield(msg,'preview_ms'),  preview_ms  = msg.preview_ms;  end
                end
            catch
                % Expected timeout or decode error, ignore
            end

            preview_s = preview_ms / 1000.0;

            % --- Compute multiple simulation steps per frame --------------
            for ss = 1:STEPS_PER_FRAME
                if t > T_END, break; end

                % Road disturbance
                if t >= BUMP_TIME
                    road = bump_height;
                else
                    road = 0;
                end

                % AI feedforward pulse
                ff = 0;
                if preview_s > 0 && t >= (BUMP_TIME - preview_s) && t < BUMP_TIME
                    ff = -bump_height;
                end

                % --- Outputs & control efforts ---
                y_pas = x_pas(1);
                y_pid = x_pid(1);  v_pid = x_pid(2);
                y_ai  = x_ai(1);  v_ai  = x_ai(2);

                ctrl_pas = 0;
                ctrl_pid = -(Kp*y_pid + Ki*int_pid + Kd*v_pid);
                ctrl_ai  = -(Kp*y_ai  + Ki*int_ai  + Kd*v_ai) + ff;

                u_pas = road;
                u_pid = road + ctrl_pid;
                u_ai  = road + ctrl_ai;

                % --- RK4 integration (plant) ---
                x_pas = rk4_step(A_plant, B_plant, x_pas, u_pas, DT);
                x_pid = rk4_step(A_plant, B_plant, x_pid, u_pid, DT);
                x_ai  = rk4_step(A_plant, B_plant, x_ai,  u_ai,  DT);

                int_pid = int_pid + y_pid * DT;
                int_ai  = int_ai  + y_ai  * DT;

                t = t + DT;
            end

            % --- Build & send telemetry packet ----------------------------
            pkt = struct();
            pkt.t        = round(t, 3);
            pkt.y_pas    = round(y_pas, 5);
            pkt.y_pid    = round(y_pid, 5);
            pkt.y_ai     = round(y_ai,  5);
            pkt.road     = round(road,  3);
            pkt.ctrl_pas = round(ctrl_pas, 4);
            pkt.ctrl_pid = round(ctrl_pid, 4);
            pkt.ctrl_ai  = round(ctrl_ai,  4);
            pkt.bump_h   = bump_height;
            pkt.prev_ms  = preview_ms;

            jsonStr = jsonencode(pkt);
            jString = String(jsonStr);
            sendPacket = DatagramPacket(jString.getBytes(), jString.length(), targetAddress, targetPort);
            try
                sendSocket.send(sendPacket);
            catch
                % Ignore send errors
            end

            % --- Pace to real-time ----------------------------------------
            elapsed = toc;
            if elapsed < LOOP_PAUSE
                pause(LOOP_PAUSE - elapsed);
            end

            step = step + 1;
        end

        fprintf('  >> Simulation pass complete (%.1fs). Looping...\n', T_END);
        pause(0.5);
    end

    %% --- Helper: single RK4 step -----------------------------------------
    function xn = rk4_step(A, B, x, u, h)
        k1 = A*x + B*u;
        k2 = A*(x + h/2*k1) + B*u;
        k3 = A*(x + h/2*k2) + B*u;
        k4 = A*(x + h*k3)   + B*u;
        xn = x + (h/6)*(k1 + 2*k2 + 2*k3 + k4);
    end

    function cleanup(sendSock, recvSock)
        if ~isempty(sendSock), sendSock.close(); end
        if ~isempty(recvSock), recvSock.close(); end
        fprintf('  >> UDP ports released.\n');
    end
end
