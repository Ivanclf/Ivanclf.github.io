@echo off
setlocal enabledelayedexpansion

:: ===== 配置区域 =====
set SOURCE_BRANCH=hexo-source
set DEPLOY_BRANCH=main
set REPO_URL=https://github.com/Ivanclf/Ivanclf.github.io.git
:: ====================

echo.
echo  开始博客部署流程...

:: 第一步：检查并提交源码分支
echo.
echo 检查源码变更...
git add .

set has_changes=0
git diff-index --quiet HEAD -- || set has_changes=1

if !has_changes! equ 1 (
    echo 检测到源码变更
    git commit -m "更新博客源码: %date% %time%" >nul
    git push origin %SOURCE_BRANCH%
    echo 已提交源码到 %SOURCE_BRANCH% 分支
) else (
    echo 源码无变更，跳过提交
)

:: 第二步：部署静态文件分支
echo.
echo 准备部署静态文件到 %DEPLOY_BRANCH% 分支...

:: 创建临时目录
set DEPLOY_DIR=.deploy_temp
if exist "%DEPLOY_DIR%" rd /s /q "%DEPLOY_DIR%"
mkdir "%DEPLOY_DIR%"

:: 克隆部署分支
echo 克隆 %DEPLOY_BRANCH% 分支...
git clone -b %DEPLOY_BRANCH% %REPO_URL% "%DEPLOY_DIR%" --depth 1 >nul 2>&1

:: 清理旧文件（保留.git）
echo  清理旧文件...
cd "%DEPLOY_DIR%"
for /f "delims=" %%i in ('dir /b /a ^| findstr /v /i ".git"') do (
    attrib -r -a -s -h "%%i" >nul 2>&1
    rd /s /q "%%i" 2>nul || del /f /q "%%i" 2>nul
)

:: 复制新文件
echo  复制新生成的静态文件...
xcopy /s /e /y "..\public\*" "." >nul

:: 检查静态文件变更
set static_changes=0
git diff-index --quiet HEAD -- || set static_changes=1

if !static_changes! equ 1 (
    echo 检测到静态文件变更
    git add . >nul
    git commit -m "更新博客静态文件: %date% %time%" >nul
    git push origin %DEPLOY_BRANCH% >nul
    echo  已部署静态文件到 %DEPLOY_BRANCH% 分支
) else (
    echo 静态文件无变更，跳过部署
)

:: 清理临时目录
cd ..
rd /s /q "%DEPLOY_DIR%" >nul 2>&1

echo.
echo 部署完成!
pause