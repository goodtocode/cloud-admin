
set curr_dir=%~dp0
set curr_drive=%curr_dir:~0,2%
%curr_drive%
cd %curr_dir%
cd ../

func host start
REM func host start --useHttps --cert host/certs\dev.myorg.com.pfx --password MyPass1234 --verbose