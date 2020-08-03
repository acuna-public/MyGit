	@echo off 
	setlocal EnableDelayedExpansion
	chcp 65001>nul
	
	set v=1.1
	
	title MyGit v!v! (c) 2015-2016, 2019 Acuna
	
	set file_full_path=%~1
	set repo_name=%~2
	set mess=%~3
	set options=%~4
	
	set file_name=%~xn1
	
	set git="C:\Program Data\Git\bin\git.exe"
	
	if [!options!] neq [--no-recursive] (
		
		echo MyGit [Version !v!]  2015-2016.
		
	)
	
	echo.
	
	set root_dir=%~dp0
	rem set root_dir=!root_dir:~0,-1!
	
	set repo_found=0
	set other_repo_found=0
	
	if not exist !root_dir!config.ini (
		
		echo [Global]> !root_dir!config.ini
		echo repos_dir=C:\path\to\repos>> !root_dir!config.ini
		echo.>> !root_dir!config.ini
		echo [Repo "your repo name"]>> !root_dir!config.ini
		echo author=your GitHub name>> !root_dir!config.ini
		echo email=your GitHub email>> !root_dir!config.ini
		echo ftp=1>> !root_dir!config.ini
		echo ftp_ssh=1>> !root_dir!config.ini
		echo ftp_server=>> !root_dir!config.ini
		echo ftp_port=21>> !root_dir!config.ini
		echo ftp_login=>> !root_dir!config.ini
		echo ftp_password=>> !root_dir!config.ini
		echo ftp_dir=>> !root_dir!config.ini
		
	)
	
	for /f "delims=" %%a in ('call "!root_dir!functions.bat" "!root_dir!config.ini" Global') do (
		
		for /f "tokens=1* delims==" %%b in ("%%a") do (
			set global_config_%%b=%%c
		)
		
	)
	
	set repos_dir=!global_config_repos_dir!\
	
	set file=!file_full_path:%repos_dir%=!
	
	if [%repo_name%]==[] (
		for /f "delims=\" %%a in ("!file!") do set repo_name=%%a
	)
	
	for /f "delims=" %%a in ('call "!root_dir!functions.bat" "!root_dir!config.ini" Repo %repo_name%') do (
		
		for /f "tokens=1* delims==" %%b in ("%%a") do (
			
			set repo_found=1
			set repo_config_%%b=%%c
			
		)
		
	)
	
	if [!repo_found!] neq [1] (
		
		echo Не удалось найти репозиторий. Выберите из существующих:
		echo.
		
		set i=0
		
		rem Конфиги репов
		
		for /f "delims=" %%a in (!root_dir!config.ini) do (
			
			set line=%%a
			
			if "!line:~0,6!"=="[Repo " (
				set /A i+=1
				
				set line=!line:[Repo "=!
				set line=!line:"]=!
				
				echo !i!: !line!
				
			)
			
		)
		
		echo.
		set /P repo_id=
		
		set i=0
		
		for /f "delims=" %%a in (!root_dir!config.ini) do (
			
			set line=%%a
			
			rem Конфиг конкретного репозитория
			
			if "!line:~0,6!"=="[Repo " (
				set /A i+=1
				
				set line=!line:[Repo "=!
				set line=!line:"]=!
				
				if [!repo_id!]==[!i!] (
					
					set repo_name=!line!
					
					for /f "delims=" %%a in ('call "!root_dir!functions.bat" "!root_dir!config.ini" Repo !repo_name!') do (
						
						for /f "tokens=1* delims==" %%b in ("%%a") do (
							
							set repo_found=1
							set repo_config_%%b=%%c
							
						)
						
					)
					
					echo.
					
				)
				
			)
			
		)
		
	)
	
	rem Настройки FTP из конфигов
	
	for /f "delims=" %%a in (!root_dir!!repo_config_ftp_settings_file!) do (
		
		for /f "tokens=1* delims==" %%b in ("%%a") do (
			set repo_config_ftp_%%b=%%c
		)
		
	)
	
	if [!repo_found!]==[1] (
		
		set repo_dir=%repos_dir%%repo_name%
		
		if ["!repo_config_ftp_dir:~0,1!"] neq ["/"] set repo_config_ftp_dir=/!repo_config_ftp_dir!
		if ["!repo_config_ftp_dir:~-1,1!"]==["/"] set repo_config_ftp_dir=!repo_config_ftp_dir:~0,-1!
		
		if [!repo_id!]==[] ( rem Репозиторий найден в папке
			
			echo Найден репозиторий %repo_name%
			echo.
			
			cd !repo_dir!
			
			if [!mess!]==[] if [!options!] neq [--no-recursive] (
				
				echo Выберите комментарий из последних добавленных или нажмите Enter и введите новый
				echo.
				
				set i=0
				
				for /f "delims=" %%a in ('%git% log --oneline -n 1 --max-count=10 --no-merges') do (
					
					set /A i+=1
					echo !i!: %%a
					
				)
				
				echo.
				set /P mess_id=
				echo.
				
				if [!mess_id!] neq [] (
					
					set i=0
					
					for /f %%a in ('%git% log --oneline -n 1 --max-count=10 --no-merges') do (
						
						set /A i+=1
						if !mess_id!==!i! set commit_id=%%a
						
					)
					
				)
				
				if [!commit_id!]==[] (
					
					echo.
					set /P mess=Введите комментарий: 
					echo.
					
				)
				
			)
			
			if ["!repo_dir:~-1,1!"] neq ["\"] set repo_dir=!repo_dir!\
			
			if [!mess_id!]==[] (
				
				%git% config --global credential.helper wincred
				
				if [!options!]==[--current-file] (
					%git% add !file!
				) else (
					%git% add .
				)
				
				set author="!repo_config_author! <!repo_config_email!>"
				
				if [!commit_id!]==[] (
					%git% commit -m "!mess!" --author=!author!
				) else (
					%git% commit -S !commit_id!
				)
				
				%git% push
				%git% pull
				
			)
			
		)
		
		if [!repo_config_ftp!]==[1] (
			
			set i=0
			
			rem Конфиг этого репозитория для деплоя на другие серверы
			
			for /f "delims=" %%a in (!root_dir!config.ini) do (
				
				set line=%%a
				
				if "!line:~0,12!"=="[Repo-Other " (
					
					set /A i+=1
					
					for /f "delims=" %%a in ('call "!root_dir!functions.bat" "!root_dir!config.ini" Repo-Other %repo_name%') do (
						
						set other_repo_found=1
						
						for /f "tokens=1* delims==" %%b in ("%%a") do (
							
							set repo_other_config_!i!_%%b=%%c
							
							rem Настройки FTP из конфигов
							
							if ["%%b"]==["ftp_settings_file"] (
								
								for /f "delims=" %%a in (!root_dir!%%c) do (
									
									for /f "tokens=1* delims==" %%b in ("%%a") do (
										set repo_other_config_!i!_ftp_%%b=%%c
									)
									
								)
								
							)
							
							set ftp_other_file_!i!=!root_dir!ftpcmd-!i!.dat
							
						)
						
					)
					
				)
				
			)
			
			if [!repo_id!] neq [] if [!mess!]==[] (
				
				echo Введите абсолютный путь к файлу на FTP:
				echo.
				set /P mess=
				
			)
			
			echo.
			set ftp_file=!root_dir!ftpcmd.dat
			
			if [!repo_config_ftp_port!]==[] set repo_config_ftp_port=21
			
			if [!repo_config_ftp_protocol!] geq [ftp] if [!repo_config_ftp_protocol!] leq [sftp] (
				
				echo open !repo_config_ftp_protocol!://!repo_config_ftp_login!:!repo_config_ftp_password!@!repo_config_ftp_server!:!repo_config_ftp_port!> "!ftp_file!"
				
				if [!repo_id!]==[] echo cd "!repo_config_ftp_dir!">> "!ftp_file!"
				echo option batch continue>> "!ftp_file!"
				
			)
			
			rem Раскидываем конфиги для разных серверов для деплоя:
			
			if [!other_repo_found!]==[1] for /l %%i in (1,1,!i!) do (
				
				if [!repo_other_config_%%i_ftp_port!]==[] set repo_other_config_%%i_ftp_port=21
				
				if [!repo_other_config_%%i_ftp_protocol!] geq [ftp] if [!repo_other_config_%%i_ftp_protocol!] leq [sftp] (
					
					echo open !repo_other_config_%%i_ftp_protocol!://!repo_other_config_%%i_ftp_login!:!repo_other_config_%%i_ftp_password!@!repo_other_config_%%i_ftp_server!:!repo_other_config_%%i_ftp_port!> "!ftp_other_file_%%i!"
					
					if [!repo_id!]==[] echo cd "!repo_other_config_%%i_ftp_dir!">> "!ftp_other_file_%%i!"
					echo option batch continue>> "!ftp_other_file_%%i!"
					
				)
				
			)
			
			if [!repo_id!]==[] (
				
				for /f %%f in ('%git% log -n 1 --name-only --oneline --diff-filter=M') do (
					
					if exist !repo_dir!%%f (
						
						set name=%%f
						set name=!name:/=\!
						
						set remote_file_path=%%~dpf
						set remote_path=!remote_file_path:%repos_dir%%repo_name%=!
						set remote_path=!remote_path:\=/!
						
						if ["!remote_path:~-1,1!"]==["/"] set remote_path=!remote_path:~0,-1!
						
						if [!repo_config_ftp_protocol!] geq [ftp] if [!repo_config_ftp_protocol!] leq [sftp] (
							
							echo mkdir "!repo_config_ftp_dir!!remote_path!">> "!ftp_file!"
							echo put "!repo_dir!!name!" "!repo_config_ftp_dir!/%%f">> "!ftp_file!"
							
						)
						
						if [!other_repo_found!]==[1] for /l %%i in (1,1,!i!) do (
							
							if [!repo_other_config_%%i_ftp_protocol!] geq [ftp] if [!repo_other_config_%%i_ftp_protocol!] leq [sftp] (
								
								echo mkdir "!repo_other_config_%%i_ftp_dir!!remote_path!">> "!ftp_other_file_%%i!"
								echo put "!repo_dir!!name!" "!repo_other_config_%%i_ftp_dir!/%%f">> "!ftp_other_file_%%i!"
								
							)
							
						)
						
					)
					
				)
				
			) else (
				
				if ["!mess:~-1,1!"]==[/] set mess=!mess:~0,-1!
				
				set remote_path=!mess:%repo_config_ftp_dir%=!
				set local_path=!repo_dir!!remote_path:/=\!
				
				if not exist "!local_path!" mkdir "!local_path!"
				
				if [!repo_config_ftp_protocol!] geq [ftp] if [!repo_config_ftp_protocol!] leq [sftp] (
					
					echo get "!repo_config_ftp_dir!!remote_path!/!file_name!" "!local_path!\!file_name!">> "!ftp_file!"
					
				)
				
			)
			
			if [!repo_config_ftp_protocol!] geq [ftp] if [!repo_config_ftp_protocol!] leq [sftp] (
				
				if [!options!] neq [--no-recursive] if [!repo_config_ftp_empty_dirs!] neq [] (
					
					echo Очистить следующие папки [y/n]?
					echo.
					
					for /f "delims=," %%f in ("!repo_config_ftp_empty_dirs!") do (
						
						set dir_path=%%f
						
						rem if ["!dir_path:~0,1!"]==["/"] set dir_path=!dir_path:~1!
						if ["!dir_path:~-1,1!"]==["/"] set dir_path=!dir_path:~0,-1!
						
						echo !dir_path!
						
					)
					
					echo.
					set /P empty_dirs=
					echo.
					
					if [!empty_dirs!]==[] set empty_dirs=n
					
					if [!empty_dirs!]==[y] (
						
						for /d %%f in (!repo_config_ftp_empty_dirs!) do (
							
							set dir_path=%%f
							if ["!dir_path:~-1,1!"]==["/"] set dir_path=!dir_path:~0,-1!
							
							echo rm "!dir_path!">> "!ftp_file!"
							
						)
						
					)
					
				)
				
				echo option batch abort>> "!ftp_file!"
				echo close>> "!ftp_file!"
				echo exit>> "!ftp_file!"
				
				winscp.com /script="!ftp_file!"
				if exist "!ftp_file!" del "!ftp_file!"
				
				if [!other_repo_found!]==[1] for /l %%i in (1,1,!i!) do (
					
					echo option batch abort>> "!ftp_other_file_%%i!"
					echo close>> "!ftp_other_file_%%i!"
					echo exit>> "!ftp_other_file_%%i!"
					
					winscp.com /script="!ftp_other_file_%%i!"
					if exist "!ftp_other_file_%%i!" del "!ftp_other_file_%%i!"
					
				)
				
			)
			
		)
		
		if [!repo_config_other_repos!] neq [] if [!options!] neq [--no-recursive] (
			
			echo.
			echo Обновить следующие репозитории [y/n]?
			echo.
			
			for /d %%a in (!repo_config_other_repos!) do (
				echo %%a
			)
			
			echo.
			set /P other_repos=
			
			if [!other_repos!]==[y] (
				for /d %%a in (!repo_config_other_repos!) do (
					"!root_dir!mygit.bat" "" "%%a" "!mess!" "--no-recursive"
				)
			)
			
		)
		
	) else echo Не найден конфиг для текущего репозитория
	
	echo.
	
	pause