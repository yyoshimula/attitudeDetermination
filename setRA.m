%% 0. Python & SDK 準備  (clear classes は pyenv の前)
pe = pyenv("Version", fullfile(getenv("HOME"), "venv/xarm/bin/python3.10"), "ExecutionMode","InProcess");

% 1) wrapper モジュールを import
xarm = py.importlib.import_module("xarm.wrapper");

% 2) クラス XArmAPI を取り出す
XArmAPI = xarm.XArmAPI;
ROBOT_IP = "192.168.1.156";

%% 1. 接続 ＆ READY
arm = xarm.XArmAPI(ROBOT_IP, prot_flag=int32(1));  % V1 強制
pause(0.5);

arm.motion_enable(pyargs('enable',true));
arm.set_mode(int32(0));     % Position
arm.set_state(int32(0));    % Ready

mod = py.importlib.import_module("xarm");