@echo off
chcp 65001 >nul
echo ================================================
echo  Mermaid MMD 右键菜单安装工具
echo ================================================
echo.

:: ── 1. 创建工具目录 ──────────────────────────────
set TOOL_DIR=%USERPROFILE%\mermaid-tool
mkdir "%TOOL_DIR%" 2>nul
echo [1/3] 工具目录: %TOOL_DIR%

:: ── 2. 生成转换脚本 mmd-to-png.bat ──────────────
set CONVERTER=%TOOL_DIR%\mmd-to-png.bat

(
    echo @echo off
    echo chcp 65001 ^>nul
    echo set "INPUT=%~1"
    echo set "OUTPUT=%~dpn1.png"
    echo echo 正在转换: %~nx1
    echo echo 输出文件: %%OUTPUT%%
    echo echo.
    echo mmdc -i "%%INPUT%%" -o "%%OUTPUT%%" -b white -s 2
    echo if %%errorlevel%%==0 ^(
    echo     echo.
    echo     echo 转换成功！
    echo     echo 文件已保存到: %%OUTPUT%%
    echo ^) else ^(
    echo     echo.
    echo     echo 转换失败，请检查 mmdc 是否正确安装。
    echo ^)
    echo echo.
    echo pause
) > "%CONVERTER%"

echo [2/3] 转换脚本已创建: %CONVERTER%

:: ── 3. 注册右键菜单（仅当前用户，无需管理员）────
reg add "HKCU\Software\Classes\.mmd" /ve /d "mmdfile" /f >nul 2>&1
reg add "HKCU\Software\Classes\.mmd" /v "Content Type" /d "text/plain" /f >nul 2>&1

reg add "HKCU\Software\Classes\mmdfile" /ve /d "Mermaid Diagram" /f >nul 2>&1

reg add "HKCU\Software\Classes\mmdfile\shell" /ve /d "Convert to PNG" /f >nul 2>&1

reg add "HKCU\Software\Classes\mmdfile\shell\Convert to PNG" /ve /d "转换为 PNG 图片" /f >nul 2>&1
reg add "HKCU\Software\Classes\mmdfile\shell\Convert to PNG" /v "Icon" /d "msedge.exe,0" /f >nul 2>&1

reg add "HKCU\Software\Classes\mmdfile\shell\Convert to PNG\command" /ve /d "cmd /c \"%CONVERTER%\" \"%%1\"" /f >nul 2>&1

echo [3/3] 右键菜单注册完成

echo.
echo ================================================
echo  安装完成！
echo  现在在任意 .mmd 文件上右键，
echo  即可看到"转换为 PNG 图片"选项。
echo  （如果没看到，重启文件资源管理器或重新登录）
echo ================================================
echo.
pause
