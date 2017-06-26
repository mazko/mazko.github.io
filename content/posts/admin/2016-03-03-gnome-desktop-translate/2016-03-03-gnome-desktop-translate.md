title: Как соорудить удобный перевод текста всего за пару минут
category: Admin
tags: REST

Стандартная ситуация: читаем какую-нибудь *e-book* на ненашем языке и видим незнакомое слово. Волшебный скрипт в помощь:

- Считывает текущий выделенный в операционной системе фрагмент текста

- Скармливает этот текст веб-сервису синтезатору речи, в ответ получает аудио файл и проигрывает. На слух как-то оно лучше запоминается :)

- Параллельно скармливает текст веб-сервису переводчику, целевой язык как в системе, парсит ответ и вытаскивает оттуда собственно сам перевод

- Выводит приятное всплывающее окошко с переведённым содержимым, даже картинка присутствует под катом

Привожу две версии скрипта *xsel-tr-notify.sh*, первая для перевода текста использует из командной строки готовое приложение *translate-shell*, тогда как вторая работает напрямую c REST API.

![screenshot]({attach}translate-ubuntu.gif){:style="width:100%; border:1px solid #ddd;"}

*xsel-tr-notify.sh*

    :::bash

    #!/usr/bin/env bash

    # chmod +x xsel-tr-notify.sh && sudo ln -s `pwd`/$_ /usr/local/bin/xsel-translate-notify
    # apt-get install libnotify-bin xsel
    # git clone https://github.com/soimort/translate-shell && cd translate-shell/ && make

    # Exit immediately if a command exits with a non-zero status.
    set -e

    # capture current OS selection into variable
    text=`xsel -o`

    # Absolute path to this script, e.g. /home/user/bin/foo.sh
    SCRIPT=$(readlink -f "$0")

    # Absolute path this script is in, thus /home/user/bin
    SCRIPTPATH=$(dirname "$SCRIPT")

    translate=`$SCRIPTPATH/translate-shell/build/trans -p -brief :${LANGUAGE:0:2} $text`

    # UI notify
    notify-send -u critical "$text" "$translate"

Как это работает ? В качестве примера нижне показан скрипт, который используют REST API Яндекса. Аналогичное API есть и у других поисковиков — Google, Bing и т.д и приложение *translate-shell* тоже его использует для перевода текста.

*xsel-tr-notify.sh*

    :::bash
    #!/usr/bin/env bash

    # chmod +x xsel-tr-notify.sh && sudo ln -s `pwd`/$_ /usr/local/bin/xsel-translate-notify
    # apt-get install mpg123 libnotify-bin xsel curl

    # Exit immediately if a command exits with a non-zero status.
    set -e

    echo "Powered by Yandex api"

    # https://tech.yandex.ru/translate/
    YA_TRNSL_KEY=your_trnsl_key_here
    # https://tech.yandex.ru/speechkit/cloud/doc/dg/concepts/speechkit-dg-tts-docpage/
    YA_TTS_KEY=your_tts_key_here

    # capture current OS selection into variable
    text=`xsel -o`

    # text to speech in background, non-blocking
    curl -sf 'https://tts.voicetech.yandex.net/generate' \
      -d "text=$text"       \
      -d 'format=mp3'       \
      -d 'lang=en-EN'       \
      -d 'speaker=zahar'    \
      -d 'emotion=good'     \
      -d "key=$YA_TTS_KEY"  \
      | mpg123 --stereo - &

    # translate text & parse json response
    translate=`curl -sf 'https://translate.yandex.net/api/v1.5/tr.json/translate' \
      -d "key=$YA_TRNSL_KEY"    \
      -d "text=$text"           \
      -d "lang=${LANGUAGE:0:2}" \
      | sed 's/.*\[\"\(.*\)\"\].*/\1/'`

    # UI notify
    notify-send -u critical "$text" "$translate"

Ключи **Яндекс** даёт бесплатно для некоммерческих целей. В простейшем случае для проверки скрипта стоит просто выделить текст и выполнить ```xsel-translate-notify```, но куда удобней выполнять это действие комбинацией клавиш.
