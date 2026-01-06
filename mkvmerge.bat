@echo off

chcp 1251 >nul
setlocal EnableDelayedExpansion

pushd %1 || (
    echo Не удалось подключиться
    exit /b 1
)


REM Собираем список папок
set count=0
for /D %%D in (*) do (
    set /a count+=1
    set "dirs[!count!]=%%D"
)

if %count%==0 (
    echo Папки не найдены
    popd
    exit /b 1
)

REM Показываем список
echo Доступные папки:
for /L %%i in (1,1,%count%) do (
    echo   %%i^) !dirs[%%i]!
)

echo.

REM Сколько папок с сезонами выбрать
set /p selectSesonCount="Сколько сезонов в вашем маняме? "

if %selectSesonCount% GTR %count% (
    echo Ошибка: слишком большое число сезонов в маняме
    popd
    exit /b 1
) else if %selectSesonCount% LSS 1 (
    echo Ошибка: слишком маленькое число сезонов в маняме
    popd
    exit /b 1
)

set /p startSeson="С какого сезона начинаем считать? "

if %startSeson% GTR %selectSesonCount% (
    echo Ошибка: слишком большое число сезона
    popd
    exit /b 1
) else if %startSeson% LSS 1 (
    echo Ошибка: слишком маленькое число сезона
    popd
    exit /b 1
)

REM Пользователь выбирает номера
set choiceIdx=0
for /L %%i in (%startSeson%,1,%selectSesonCount%) do (
    set /p choiceId="Введите номер папки с сезоном %%i из списка выше: "
    
    if !choiceId! GTR %count% (
        echo Ошибка: нет такой папки
        popd
        exit /b 1
    ) else if !choiceId! LSS 1 (
        echo Ошибка: нет такой папки
        popd
        exit /b 1
    )
    
    call set "selected[%%i]=%%dirs[!choiceId!]%%"
)

echo.

REM Результат выбора
echo Вы выбрали:
for /L %%i in (%startSeson%,1,%selectSesonCount%) do (
    echo Сезон %%i^: !selected[%%i]!
)

REM Вводим нормальное название маняме
set /p correctName="Введите корректное название вашего маняме: "

REM Делаем заготовки папок с сезонами
if not exist %correctName% mkdir %correctName%
cd %correctName%
for /L %%i in (%startSeson%,1,%selectSesonCount%) do (
    if not exist \%correctName%\s0%%i mkdir \%correctName%\s0%%i
)
cd \

REM Делаем мёрж
for /L %%i in (%startSeson%,1,%selectSesonCount%) do (
    cd \!selected[%%i]!
    if %2 EQU 0 (
        for %%f in ("*.mkv","*.mp4","*.hevc","*.avi","*.h264") do (
            if exist "%%~nf.mka" (
                if exist "%%~nf.ass" (
                    "%PROGRAMFILES%\MkvToolNix\mkvmerge.exe" --output "\%correctName%\s0%%i\%%~nf.mkv" --default-track 0:yes --language 0:rus ^( "%%~nf.ass" ^) --default-track 0:yes --language 0:rus ^( "%%~nf.mka" ^) --default-track 1:no --default-track 0:yes --language 0:jpn ^( "%%f" ^) --title "%%~nf" --track-order 2:0,1:0,0:0 --disable-track-statistics-tags --no-global-tags
                ) else (
                    "%PROGRAMFILES%\MkvToolNix\mkvmerge.exe" --output "\%correctName%\s0%%i\%%~nf.mkv" --default-track 0:yes --language 0:rus ^( "%%~nf.mka" ^) --default-track 1:no --default-track 0:yes --language 0:jpn ^( "%%f" ^) --title "%%~nf" --track-order 2:0,1:0,0:0 --disable-track-statistics-tags --no-global-tags
                )
            ) else if exist "%%~nf.ass" (
                "%PROGRAMFILES%\MkvToolNix\mkvmerge.exe" --output "\%correctName%\s0%%i\%%~nf.mkv" --default-track 0:yes --language 0:rus ^( "%%~nf.ass" ^) --default-track 1:yes --default-track 0:yes --language 0:jpn ^( "%%f" ^) --title "%%~nf" --track-order 2:0,1:0,0:0 --disable-track-statistics-tags --no-global-tags
            )
        )
    ) else if %2 EQU 1 (
        REM считаем видео файлы
        set videoCount=0
        for /f "delims=" %%f in ('dir /b /o:n *.mkv *.mp4 *.hevc *.avi *.h264') do (
            set /a videoCount+=1
            set "video[!videoCount!]=%%f"
        )
        
        REM фильтруем только корректные папки с аудио
        set audioGroupCount=0
        for /D %%q in (Audio*) do (
            set audioFileCount=0
            for %%a in ("%%q\*") do (
                set /a audioFileCount+=1
            )
            REM пропускаем папки, где количество файлов отличается от количества видео
            if !audioFileCount! EQU !videoCount! (
                set /a audioGroupCount+=1
                set "audioGroup[!audioGroupCount!]=%%q"
            )
        )
        
        REM фильтруем только корректные папки с субтитрами
        set subGroupCount=0
        for /D %%q in (Sub*) do (
            set subFileCount=0
            for %%s in ("%%q\*") do (
                set /a subFileCount+=1
            )
            REM пропускаем папки, где количество файлов отличается от количества видео
            if !subFileCount! EQU !videoCount! (
                set /a subGroupCount+=1
                set "subGroup[!subGroupCount!]=%%q"
            )
        )
        
        REM формируем итоговую команду
        for /L %%n in (1,1,!videoCount!) do (
            set "cmd=^"%PROGRAMFILES%\MkvToolNix\mkvmerge.exe^" --output ^"\%correctName%\s0%%i\!video[%%n]!^""
            
            for /L %%a in (1,1,!audioGroupCount!) do (
                set "grpName=!audioGroup[%%a]!"
                
                set curCount=0
                for /f "delims=" %%v in ('dir /b /o:n "!grpName!\*"') do (
                    set /a curCount+=1
                    if !curCount! EQU %%n (
                        if %%a==1 (
                            set "cmd=!cmd! --language 0:rus --default-track 0:yes ^( ^"!grpName!\%%v^" ^)"
                        ) else (
                            set "cmd=!cmd! --language 0:rus --default-track 0:no ^( ^"!grpName!\%%v^" ^)"
                        )
                    )
                )
            )
            
            for /L %%s in (1,1,!subGroupCount!) do (
                set "grpName=!subGroup[%%s]!"
                
                set curCount=0
                for /f "delims=" %%r in ('dir /b /o:n "!grpName!\*"') do (
                    set /a curCount+=1
                    if !curCount! EQU %%n (
                        if %%s==1 (
                            set "cmd=!cmd! --language 0:rus --default-track 0:yes ^( ^"!grpName!\%%r^" ^)"
                        ) else (
                            set "cmd=!cmd! --language 0:rus --default-track 0:no ^( ^"!grpName!\%%r^" ^)"
                        )
                    )
                )
            )
            
            set "cmd=!cmd! --default-track 1:no --default-track 0:yes --language 0:jpn ^( ^"!video[%%n]!^" ^) --disable-track-statistics-tags --no-global-tags"
            echo !cmd!
            echo.
            !cmd!
            echo.
        )
    ) else (
        echo Ошибка: некорректный вариант мержа
        popd
        exit /b 1
    )
)
cd \

REM Делаем корректные наименования
for /L %%i in (%startSeson%,1,%selectSesonCount%) do (
    cd \%correctName%\s0%%i
    set episodeCount=0
    for /f "delims=" %%f in ('dir /b /o:n *.mkv') do (
        set /a episodeCount+=1
        if !episodeCount! GEQ 10 (
            echo %%~f rename to %correctName% s0%%ie!episodeCount!%%~xf
            ren "%%f" "%correctName% s0%%ie!episodeCount!%%~xf"
        ) else (
            echo %%~f rename to %correctName% s0%%ie0!episodeCount!%%~xf
            ren "%%f" "%correctName% s0%%ie0!episodeCount!%%~xf"
        )
    )
)
cd \

popd