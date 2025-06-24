

% jpegファイルをすべて取得
files = dir('data/20250507/*.jpeg')

% 保存先のフォルダ（必要に応じて変更）
output_folder = 'data/20250507/renamed/';

% フォルダが存在しない場合は作成
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% 各ファイルについて処理
for i = 1:length(files)
    % 元のファイル名とパス
    old_name = files(i).name;
    old_path = fullfile(files(i).folder, old_name);

    % 新しいファイル名（例: image_000.jpeg）
    new_name = sprintf('image_%03d.jpeg', i-1);
    new_path = fullfile(output_folder, new_name);

    % ファイルをコピーまたは移動（rename）
    copyfile(old_path, new_path);

    fprintf('Renamed %s → %s\n', old_name, new_name);
end