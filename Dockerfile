FROM php:8.0-apache

RUN set -xe && \
    echo "deb http://repo.suhosin.org/ debian-jessie main" > /etc/apt/sources.list.d/suhosin.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B12D0447319F1ADB && \
    apt update && \
    apt install -y php5-suhosin-extension && \
    cp /etc/php5/mods-available/suhosin.ini /usr/local/etc/php/conf.d/ && \
    echo "suhosin.executor.disable_eval = On" >> /usr/local/etc/php/conf.d/suhosin.ini && \
    cp /usr/lib/php5/20131226/suhosin.so $(php -i | grep "^extension_dir" | awk -F" => " '{print $3}') && \

    apt install -y --no-install-recommends \
        libjpeg-dev libpng-dev libfreetype6-dev \
        libcurl4-openssl-dev \
        openssl libc-client-dev libkrb5-dev \
        libicu-dev \
        libmcrypt-dev \
        ffmpegthumbnailer && \

    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install -j$(nproc) curl exif gd iconv imap intl json mcrypt mysql mysqli && \

    echo "disable_functions = apache_child_terminate,apache_setenv,curl_multi_exec,define_syslog_variables,dl,escapeshellarg,escapeshellcmd,eval,exec,fp,fput,ftp_connect,ftp_exec,ftp_get,ftp_login,ftp_nb_fput,ftp_put,ftp_raw,ftp_rawlist,highlight_file,ini_alter,ini_get_all,ini_restore,inject_code,mysql_pconnect,openlog,parse_ini_file,passthru,pcntl_alarm,pcntl_exec,pcntl_fork,pcntl_get_last_error,pcntl_getpriority,pcntl_setpriority,pcntl_signal,pcntl_signal_dispatch,pcntl_sigprocmask,pcntl_sigtimedwait,pcntl_sigwaitinfo,pcntl_strerror,pcntl_wait,pcntl_waitpid,pcntl_wexitstatus,pcntl_wifexited,pcntl_wifsignaled,pcntl_wifstopped,pcntl_wstopsig,pcntl_wtermsig,phpAds_remoteInfo,phpAds_XmlRpc,phpAds_xmlrpcDecode,phpAds_xmlrpcEncode,phpcredits,php_ini_scanned_files,php_uname,popen,posix_getpwuid,posix_kill,posix_mkfifo,posix_setpgid,posix_setsid,posix_setuid,posix_uname,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,shell_exec,show_source,symlink,syslog,system,url_fopen,virtual" > /usr/local/etc/php/php.ini && \

    a2enmod rewrite headers cache && \

    sed '/^exec apache2/i \if [ ! -z ${FUNCTIONS+x} ]; then\n\tsed -r "/^disable_functions/ s/${FUNCTIONS}//g" -i /usr/local/etc/php/php.ini\nfi' -i /usr/local/bin/apache2-foreground && \

    apt-get autoremove -y && \
    apt-get clean all

CMD ["apache2-foreground"]
