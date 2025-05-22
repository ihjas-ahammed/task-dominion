
REM Script to install Flutter and build for Windows

REM **Important:**
REM 1.  Run this script as an administrator.  Right-click the file and select "Run as administrator".
REM 2.  This script assumes you want to install Flutter and its dependencies in the C:\flutter directory.  If you want to install it elsewhere, change the FLUTTER_INSTALL_PATH variable below.
REM 3. This script requires git to be installed. If git is not installed, the script will try to install it using chocolatey.
REM 4. This script uses chocolatey to install some dependencies. If you don't have chocolatey, it will attempt to install it.
REM 5.  This script assumes you have an internet connection.
REM 6.  This script will download the Flutter SDK from the official source.
REM 7.  This script adds the flutter and dart to your system path.
REM 8.  This script accepts an optional parameter for the project directory. If provided, it will change to that directory before building.
REM 9.  This script will build the Flutter project for Windows.

SETLOCAL

REM Configuration
SET FLUTTER_INSTALL_PATH=C:\flutter
SET FLUTTER_VERSION=3.19.0  REM You can change this to a specific version if needed, or just use latest
SET PROJECT_DIRECTORY=%1
SET BUILD_MODE=release  REM Or 'debug', 'profile'


REM Check for admin privileges
fltmc >nul 2>&1 || (
    echo.
    echo This script requires administrator privileges. Please run it as administrator.
    echo.
    pause
    exit /b 1
)

REM Function to display messages
:message
echo.
echo %*
echo.
goto :eof

REM Function to check if a program is installed
:isInstalled
where /Q %1
goto :eof

REM Function to run a command and handle errors
:runCommand
echo Running command: %*
%*
if errorlevel 1 (
    echo Error running command.  Exiting.
    pause
    exit /b %errorlevel%
)
goto :eof

REM Check if Chocolatey is installed
if not exist "%ProgramData%\chocolatey\choco.exe" (
    :message "Chocolatey is not installed. Installing Chocolatey..."
    @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    if not exist "%ProgramData%\chocolatey\choco.exe" (
        :message "Failed to install Chocolatey.  Please install it manually from https://chocolatey.org/install and re-run this script."
        pause
        exit /b 1
    )
)

REM Upgrade Chocolatey
:message "Upgrading Chocolatey..."
:runCommand choco upgrade chocolatey -y

REM Check if git is installed
if not :isInstalled "git" (
    :message "git is not installed. Installing git..."
    :runCommand choco install git -y
)

REM Check if the Flutter installation directory exists
if not exist "%FLUTTER_INSTALL_PATH%" (
    :message "Flutter installation directory does not exist. Creating it..."
    mkdir "%FLUTTER_INSTALL_PATH%"
)

REM Download Flutter SDK
:message "Downloading Flutter SDK..."

if "%FLUTTER_VERSION%"=="latest" (
    :runCommand git clone -b main https://github.com/flutter/flutter.git "%FLUTTER_INSTALL_PATH%"
) else (
    :runCommand git clone -b "v%FLUTTER_VERSION%" https://github.com/flutter/flutter.git "%FLUTTER_INSTALL_PATH%"
)


REM Set environment variables
:message "Setting environment variables..."
setx path "%PATH%;%FLUTTER_INSTALL_PATH%\bin;%FLUTTER_INSTALL_PATH%\dart-sdk\bin" /M
set "PATH=%PATH%;%FLUTTER_INSTALL_PATH%\bin;%FLUTTER_INSTALL_PATH%\dart-sdk\bin"

REM Run flutter doctor
:message "Running flutter doctor..."
"%FLUTTER_INSTALL_PATH%\bin\flutter" doctor -v

REM Accept all licenses
:message "Accepting all licenses..."
"%FLUTTER_INSTALL_PATH%\bin\flutter" doctor --android-licenses

REM Change to the project directory if provided
if defined PROJECT_DIRECTORY (
    if exist "%PROJECT_DIRECTORY%" (
        :message "Changing to project directory: %PROJECT_DIRECTORY%"
        cd /d "%PROJECT_DIRECTORY%"
    ) else (
        :message "Project directory not found: %PROJECT_DIRECTORY%.  Building from current directory."
    )
)

REM Build the Flutter project for Windows
:message "Building Flutter project for Windows (%BUILD_MODE% mode)..."
"%FLUTTER_INSTALL_PATH%\bin\flutter" build windows --%BUILD_MODE%

:message "Flutter installation and Windows build complete!"
:message "The output is located in the 'build\windows\runner\%BUILD_MODE%' directory."

ENDLOCAL
pause
exit /b 0
