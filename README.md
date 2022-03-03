# DPABI_without_GUI
Process brain function images without GUI

Version：
DPABI: DPABI_V6.1_220101

DPABI难以在没有图形界面的服务器上使用，本文通过[意疏](https://blog.csdn.net/sinat_35907936/article/details/113425845?spm=1001.2014.3001.5502)的方案实现了在无GUI的服务器上通过DPABI处理fMRI的功能。

原文链接：https://blog.csdn.net/sinat_35907936/article/details/113425845

### 1 服务器`DPARSFA_run`函数修改 (可通过DPARSFA_run.m直接覆盖)

​		一般情况下不会选择`Crop T1`去除脖子，在GUI环境下，`DPARSFA_run`会在找不到co开头的`nifit`时会弹窗-`no co* T1 image is found`，选择`yes`可以用T1图像代替继续进行，**在无GUI环境时会报错**。

修改方法：查找出`DPARSFA_run.m`文件中所有含`questdlg`的代码段，并做如下替换，共需要替换5处。目的是在没有co*T1时能够直接用T1接着运行。

```matlab
   button = questdlg(['No co* T1 image (T1 image which is reoriented to the nearest orthogonal direction to ''canonical space'' and removed excess air surrounding the individual as well as parts of the neck below the cerebellum) is found. Do you want to use the T1 image without co? Such as: ',DirImg(1).name,'?'],'No co* T1 image is found','Yes','No','Yes');
    if strcmpi(button,'Yes')
        UseNoCoT1Image=1;
    else
        return;
    end
```

替换后代码

```matlab
    if AutoDataProcessParameter.IsAllowGUI == 0  % no GUI no pop-up windows
         UseNoCoT1Image=1;
         disp('WARNING：No co* T1 image, use NoCoT1Image instead');
    else
         button = questdlg(['No co* T1 image (T1 image which is reoriented to the nearest orthogonal direction to ''canonical space'' and removed excess air surrounding the individual as well as parts of the neck below the cerebellum) is found. Do you want to use the T1 image without co? Such as: ',DirImg(1).name,'?'],'No co* T1 image is found','Yes','No','Yes');
        if strcmpi(button,'Yes')
            UseNoCoT1Image=1;
        else
            return;
        end
    end
```

另外，在无GUI的情况下，默认不会产生`PicturesForChkNormalization`文件夹，而它是后面做质量检测时重要的参考，所以必须要产生它。查找出所有的`Generate the pictures only if GUI is allowed`字段，共两处，将其所在行的if语句注释掉，并且注释其对应的end。

```matlab
%     if AutoDataProcessParameter.IsAllowGUI %YAN Chao-Gan, 161011. Generate the pictures only if GUI is allowed.
```

### 2 任务提交代码

​		通过输入参数更新Cfg结构体，运行DPARSFA处理流程并生成log文件。

参数说明：

```
Cfg_file: 在GUI上选择并保存的.mat文件
work_dir: dpabi指定的工作目录
StartingDirName: DPARSFA处理流程的起始目录，如FunRaw
ROI_alats_name: 指定脑图谱文件名，指定脑图谱需存储于dpabi的Template目录下
```



```matlab
function dpabi_noGUI(Cfg_file,work_dir,StartingDirName,ROI_altas_name)

% use dpabi pipeline without GUI
% Cfg_file, work_dir , StartingDirName and ROI_atlas_name in dpabi as fuction inputs.
% Cfg_file mat file from dipabi GUI selection saving.
% if you dont do FC with ROI altas, make ROI_altas_name='', if not, make  ROI_altas_name= 'altas_name' such as 'aal.nii'
% command: matlab -nodisplay "$nojvm" -nosplash -r "dpabi_noGUI('/home/pc/fMRI/data/tmp.mat','/home/pc/fMRI/data','FunImg', 'aal.nii')" 
% kill progress command: ps -ef|grep 'matlab'|grep -v  'ii'|cut -c 9-16|xargs kill -9

    dpabi_dir = '/XXX/DPABI_V6.1_220101';   %dpabi install dir，需要自行修改路径
    template_dir = [dpabi_dir,'/Templates/'];
    
    sub_dir = dir([work_dir, '/',StartingDirName]);
    log_file = [work_dir, '/log.txt'];

    [D1, ~] = size(sub_dir);
    SubjectID = cell(D1-2, 1);


    for i = 3:D1
        SubjectID{i-2} = sub_dir(i).name;
    end
    

    load(Cfg_file)
    Cfg.WorkingDir = '';
    Cfg.DataProcessDir  = '';
    Cfg.SubjectID = SubjectID;
    if Cfg.IsCalFC == 1 || Cfg.IsExtractROISignals == 1
        if size(ROI_altas_name) == 0
            disp('there is no ROI_atlas_name')
            return
        else 
            Cfg.CalFC.ROIDef = {[template_dir, ROI_altas_name]};
        end
    end
    Cfg.StartingDirName = StartingDirName;
    
    f1 = fopen(log_file,'w+');
    diary(log_file)
    diary on
    
    DPARSFA_run(Cfg,work_dir,'',0);

    fclose(f1);

    disp('Success!')
    diary off

end
```

### 3 示例

#### Step 1 本地电脑GUI选择参数并保存成`.mat`文件

<img width="629" alt="image" src="https://user-images.githubusercontent.com/23079709/156490250-6305c5ee-a807-4ecf-bda9-5a1613093108.png">


#### Step 2 `.mat`文件上传至服务器

#### Step 3 在服务器运行命令调用dpabi_noGUI

```bash
./matlab -nodisplay "$nojvm" -nosplash -r "dpabi_noGUI('/XXX/***.mat', '/XXX/XXX', 'FunRaw', 'XXX.nii')"
```

