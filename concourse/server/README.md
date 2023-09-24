# Concourse CI サーバ

## 参照資料

- 以下の資料の内容を実施していることを前提とする

    - [Concourse CI のイントール](https://github.com/moriyamaES/concourse-install)

    - [Vaultとの連携](https://github.com/moriyamaES/vault-install)

    - [Concourse CI からGitHubへの書込み](https://github.com/moriyamaES/vault-install)

<del>

## Concourse CI の停止

- これまでの設定で起動していた Concourse CI を停止する

    ```sh
    $ cd ~/concourse-install/
    ```
    ```sh
    $ ll
    合計 180
    -rw-r--r--. 1 root root 164318  9月  9 23:26 README.md
    -rw-r--r--. 1 root root   2021  9月  9 23:26 credentials.yml
    -rw-r--r--. 1 root root   1548  9月 10 14:12 docker-compose.yml
    -rw-r--r--. 1 root root   1548  9月 10 14:11 docker-compose.yml_old
    drwxr-xr-x. 2 root root     45  9月  9 23:26 imgs
    drwxr-xr-x. 4 root root     47  9月  9 23:26 keys
    -rw-r--r--. 1 root root   2985  9月  9 23:26 pipeline.yml
    drwxr-xr-x. 4 root root     96  9月 10 10:39 tutorials
    ```
    ```sh
    $ docker ps -a | grep conc
    97ad8c1afbe6   concourse/concourse                  "dumb-init /usr/loca…"   5 days ago    Up 5 days                                                                      concourse-install-worker-1
    6a071162b0dc   concourse/concourse                  "dumb-init /usr/loca…"   5 days ago    Up 5 days                          0.0.0.0:8080->8080/tcp, :::8080->8080/tcp   concourse-install-web-1
    430a4ad2994e   postgres                             "docker-entrypoint.s…"   5 days ago    Up 5 days                          5432/tcp                                    concourse-install-db-1
    ```

    ```sh
    $ docker-compose down
    [+] Running 4/4
    ✔ Container concourse-install-worker-1  Removed                                                                                                                                                10.7s 
    ✔ Container concourse-install-web-1     Removed                                                                                                                                                10.7s 
    ✔ Container concourse-install-db-1      Removed                                                                                                                                                 0.7s 
    ✔ Network concourse-install_default     Removed  
    ```

</del>

## Concourse CI の URL を localhost から変更する

- Concourse CI の URL を `localhost` であることが気に入らないので、サーバのIPアドレス(`10.1.1.200`)に`docker-compose.yml`を変更する。

<del>


- 変更内容は以下

    ```diff
    $ diff -u ~/concourse-install/docker-compose.yml ./concourse/server/docker-compose.yml 
    --- /root/concourse-install/docker-compose.yml  2023-09-10 14:12:28.547639661 +0900
    +++ ./concourse/server/docker-compose.yml       2023-09-16 10:37:15.164159742 +0900
    @@ -21,7 +21,7 @@
        ports: ["8080:8080"]
        volumes: ["./keys/web:/concourse-keys"]
        environment:
    -      CONCOURSE_EXTERNAL_URL: http://localhost:8080
    +      CONCOURSE_EXTERNAL_URL: http://10.1.1.200:8080
        CONCOURSE_POSTGRES_HOST: db
        CONCOURSE_POSTGRES_USER: concourse_user
        CONCOURSE_POSTGRES_PASSWORD: concourse_pass
    ```

- 変更後の内容は以下

    ```sh
    $ cat ./concourse/server/docker-compose.yml 
    version: '3'

    services:
    db:
        image: postgres
        environment:
        POSTGRES_DB: concourse
        POSTGRES_USER: concourse_user
        POSTGRES_PASSWORD: concourse_pass
        logging:
        driver: "json-file"
        options:
            max-file: "5"
            max-size: "10m"

    web:
        image: concourse/concourse
        command: web
        links: [db]
        depends_on: [db]
        ports: ["8080:8080"]
        volumes: ["./keys/web:/concourse-keys"]
        environment:
        CONCOURSE_EXTERNAL_URL: http://10.1.1.200:8080
        CONCOURSE_POSTGRES_HOST: db
        CONCOURSE_POSTGRES_USER: concourse_user
        CONCOURSE_POSTGRES_PASSWORD: concourse_pass
        CONCOURSE_POSTGRES_DATABASE: concourse
        CONCOURSE_ADD_LOCAL_USER: test:test
        CONCOURSE_MAIN_TEAM_LOCAL_USER: test
        CONCOURSE_VAULT_URL: http://10.1.1.200:8200
        CONCOURSE_VAULT_AUTH_BACKEND: "approle"
        CONCOURSE_VAULT_AUTH_PARAM: "role_id:2bf6997c-c123-5e25-3e22-ebe3c539ff16,secret_id:18cbe4e2-27da-bb78-18d2-9b0cd47f8f6c"

        logging:
        driver: "json-file"
        options:
            max-file: "5"
            max-size: "10m"

    worker:
        image: concourse/concourse
        command: worker
        privileged: true
        depends_on: [web]
        volumes: ["./keys/worker:/concourse-keys"]
        links: [web]
        stop_signal: SIGUSR2
        environment:
        CONCOURSE_TSA_HOST: web:2222
        # enable DNS proxy to support Docker's 127.x.x.x DNS server
        CONCOURSE_GARDEN_DNS_PROXY_ENABLE: "true"
        logging:
        driver: "json-file"
        options:
            max-file: "5"
            max-size: "10m"
    ```

## Concourse CI の WebUI にログインする

- concourse Web UIにログインする

    ```sh
    $ fly --target tutorial login --concourse-url http://10.1.1.200:8080
    ```

    - 操作

    - `http://localhost:8080/login?fly_port=43269` でホストOSのブラウザにアクセスし、表示されたtokenを貼り付ける
    - ユーザID: `test`、パスワード: `test` とする
    - 上記操作をすると、Concourse CI のWeb UIにログインできる

        ```
        logging in to team 'main'

        navigate to the following URL in your browser:

        http://localhost:8080/login?fly_port=43269

        or enter token manually (input hidden): 
        target saved
        ```

    - 結果（エラー発生）

        ```sh
        fly --target tutorial login --concourse-url http://10.1.1.200:8080
        logging in to team 'main'

        could not reach the Concourse server called tutorial:

            Get "http://10.1.1.200:8080/api/v1/info": dial tcp 10.1.1.200:8080: connect: connection refused

        is the targeted Concourse running? better go catch it lol
        ```

- `fly`コマンドのコンフィグを修正しなければいけないかも

    ```sh
    $ cd ~
    ```

    ```sh
    $ ll -a | grep fly
    -rw-------.  1 root root       149  9月 16 07:27 .flyrc
    -rw-r--r--.  1 root root  75450698  8月 31 20:58 fly
    ```

- `fly`コマンドのコンフィグに`http://localhost:8080`が残っている。

    ```sh
    $ cat .flyrc 
    targets:
    tutorial:
        api: http://localhost:8080
        team: main
        token:
        type: bearer
        value: PQ5R46KveX6fPzkCaqA2vwkTIoV6lQVlAAAAAA
    ```

- バックアップ後、修正

    ```sh
    $ cp .flyrc .flyrc.`date +%y%m%d%H%M%S`
    ```

    ```sh
    ll -a | grep fly
    -rw-------.  1 root root       149  9月 16 07:27 .flyrc
    -rw-------.  1 root root       149  9月 16 11:04 .flyrc.230916110408
    -rw-r--r--.  1 root root  75450698  8月 31 20:58 fly
    ```

- 変更箇所

    ```diff
    $ diff -u .flyrc.230916110408 .flyrc
    --- .flyrc.230916110408 2023-09-16 11:04:08.222618581 +0900
    +++ .flyrc      2023-09-16 11:07:59.948970313 +0900
    @@ -1,6 +1,6 @@
    targets:
    tutorial:
    -    api: http://localhost:8080
    +    api: http://10.1.1.200:8080
        team: main
        token:
        type: bearer
    ```

- 変更後

    ```sh
    # cat  .flyrc
    targets:
    tutorial:
        api: http://10.1.1.200:8080
        team: main
        token:
        type: bearer
        value: PQ5R46KveX6fPzkCaqA2vwkTIoV6lQVlAAAAAA
    ```

## そもそも Concourse CI を起動していなかった


- Concourse CI を起動

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/server/
    ```

    ```sh
    ll
    合計 12
    -rw-r--r--. 1 root root 8051  9月 16 11:16 README.md
    -rw-r--r--. 1 root root 1549  9月 16 10:37 docker-compose.yml
    ```

    ```sh
    docker-compose up -d
    [+] Running 4/4
    ✔ Network server_default     Created                                                                                                                                                            0.4s 
    ✔ Container server-db-1      Started                                                                                                                                                            0.3s 
    ✔ Container server-web-1     Started                                                                                                                                                            0.1s 
    ✔ Container server-worker-1  Started
    ```

- ポートの待ち受け状況を確認

    ```sh
    # netstat -atnu | grep -e '10.1.1.200'
    tcp        0      0 10.1.1.200:8201         0.0.0.0:*               LISTEN     
    tcp        0      0 10.1.1.200:8200         0.0.0.0:*               LISTEN     
    tcp        0     60 10.1.1.200:22           10.1.1.150:49321        ESTABLISHED 
    ```

## 再度Concourse CI へログイン

- concourse Web UIにログインする

    ```sh
    $ fly --target tutorial login --concourse-url http://10.1.1.200:8080
    ```

- 多分、docker-compose のことを知らないと、対応できないとおもうので元にmどす

## Concourse CI の URL を localhost に戻す変更する

- Concourse CI の URL を サーバのIPアドレス(`10.1.1.200`) にしようとしたが、上手くいかないので、`localhost` に戻す。

- 以下のコマンドを実行

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/server/
    ```

    ```sh
    docker-compose down
    [+] Running 4/4
    ✔ Container server-worker-1  Removed                                                                                                                                                                                                                                                                    0.0s 
    ✔ Container server-web-1     Removed                                                                                                                                                                                                                                                                    0.0s 
    ✔ Container server-db-1      Removed                                                                                                                                                                                                                                                                    0.5s 
    ✔ Network server_default     Removed  
    ```  

- `.flyrc` を元に戻す

    ```sh
    $ cd ~
    ```

    ```sh
    $ ll -a | grep  fly
    -rw-------.  1 root root       150  9月 16 11:07 .flyrc
    -rw-------.  1 root root       149  9月 16 11:04 .flyrc.230916110408
    -rw-r--r--.  1 root root  75450698  8月 31 20:58 fly
    ```

    ```sh
    $ cd ~
    [root@control-plane ~]
    # ll -a | grep  fly
    -rw-------.  1 root root       150  9月 16 11:07 .flyrc
    -rw-------.  1 root root       149  9月 16 11:04 .flyrc.230916110408
    -rw-r--r--.  1 root root  75450698  8月 31 20:58 fly
    [root@control-plane ~]
    # cat .flyrc.230916110408 
    targets:
    tutorial:
        api: http://localhost:8080
        team: main
        token:
        type: bearer
        value: PQ5R46KveX6fPzkCaqA2vwkTIoV6lQVlAAAAAA
    [root@control-plane ~]
    # cp .flyrc.230916110408 .flyrc
    cp: `.flyrc' を上書きしますか? y
    [root@control-plane ~]
    # cat .flyrc
    targets:
    tutorial:
        api: http://localhost:8080
        team: main
        token:
        type: bearer
        value: PQ5R46KveX6fPzkCaqA2vwkTIoV6lQVlAAAAAA
    ```

- `docker-compose.yml`をもとに戻す

    ```sh
    # cat  ~/concourse-install/docker-compose.yml
    version: '3'

    services:
    db:
        image: postgres
        environment:
        POSTGRES_DB: concourse
        POSTGRES_USER: concourse_user
        POSTGRES_PASSWORD: concourse_pass
        logging:
        driver: "json-file"
        options:
            max-file: "5"
            max-size: "10m"

    web:
        image: concourse/concourse
        command: web
        links: [db]
        depends_on: [db]
        ports: ["8080:8080"]
        volumes: ["./keys/web:/concourse-keys"]
        environment:
        CONCOURSE_EXTERNAL_URL: http://localhost:8080
        CONCOURSE_POSTGRES_HOST: db
        CONCOURSE_POSTGRES_USER: concourse_user
        CONCOURSE_POSTGRES_PASSWORD: concourse_pass
        CONCOURSE_POSTGRES_DATABASE: concourse
        CONCOURSE_ADD_LOCAL_USER: test:test
        CONCOURSE_MAIN_TEAM_LOCAL_USER: test
        CONCOURSE_VAULT_URL: http://10.1.1.200:8200
        CONCOURSE_VAULT_AUTH_BACKEND: "approle"
        CONCOURSE_VAULT_AUTH_PARAM: "role_id:2bf6997c-c123-5e25-3e22-ebe3c539ff16,secret_id:18cbe4e2-27da-bb78-18d2-9b0cd47f8f6c"

        logging:
        driver: "json-file"
        options:
            max-file: "5"
            max-size: "10m"

    worker:
        image: concourse/concourse
        command: worker
        privileged: true
        depends_on: [web]
        volumes: ["./keys/worker:/concourse-keys"]
        links: [web]
        stop_signal: SIGUSR2
        environment:
        CONCOURSE_TSA_HOST: web:2222
        # enable DNS proxy to support Docker's 127.x.x.x DNS server
        CONCOURSE_GARDEN_DNS_PROXY_ENABLE: "true"
        logging:
        driver: "json-file"
        options:
            max-file: "5"
            max-size: "10m"
    [root@control-plane ~]
    # cp  ~/concourse-install/docker-compose.yml ~/cicd-repo-for-manifesto/concourse/server/docker-compose.yml 
    cp: `/root/cicd-repo-for-manifesto/concourse/server/docker-compose.yml' を上書きしますか? y
    [root@control-plane ~]
    # cp  ~/ce~/cicd-repo-for-manifesto/concourse/server/docker-compose.yml 
    bash: ose.yml: コマンドが見つかりませんでした...
    [root@control-plane ~]
    # 
    [root@control-plane ~]
    # cat ~/cicd-repo-for-manifesto/concourse/server/docker-compose.yml 
    version: '3'

    services:
    db:
        image: postgres
        environment:
        POSTGRES_DB: concourse
        POSTGRES_USER: concourse_user
        POSTGRES_PASSWORD: concourse_pass
        logging:
        driver: "json-file"
        options:
            max-file: "5"
            max-size: "10m"

    web:
        image: concourse/concourse
        command: web
        links: [db]
        depends_on: [db]
        ports: ["8080:8080"]
        volumes: ["./keys/web:/concourse-keys"]
        environment:
        CONCOURSE_EXTERNAL_URL: http://localhost:8080
        CONCOURSE_POSTGRES_HOST: db
        CONCOURSE_POSTGRES_USER: concourse_user
        CONCOURSE_POSTGRES_PASSWORD: concourse_pass
        CONCOURSE_POSTGRES_DATABASE: concourse
        CONCOURSE_ADD_LOCAL_USER: test:test
        CONCOURSE_MAIN_TEAM_LOCAL_USER: test
        CONCOURSE_VAULT_URL: http://10.1.1.200:8200
        CONCOURSE_VAULT_AUTH_BACKEND: "approle"
        CONCOURSE_VAULT_AUTH_PARAM: "role_id:2bf6997c-c123-5e25-3e22-ebe3c539ff16,secret_id:18cbe4e2-27da-bb78-18d2-9b0cd47f8f6c"

        logging:
        driver: "json-file"
        options:
            max-file: "5"
            max-size: "10m"

    worker:
        image: concourse/concourse
        command: worker
        privileged: true
        depends_on: [web]
        volumes: ["./keys/worker:/concourse-keys"]
        links: [web]
        stop_signal: SIGUSR2
        environment:
        CONCOURSE_TSA_HOST: web:2222
        # enable DNS proxy to support Docker's 127.x.x.x DNS server
        CONCOURSE_GARDEN_DNS_PROXY_ENABLE: "true"
        logging:
        driver: "json-file"
        options:
            max-file: "5"
            max-size: "10m"
    ```

- concourse CI を起動する

    ```sh
    # cd ~/cicd-repo-for-manifesto/concourse/server/
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/server (main)]
    # ll 
    合計 16
    -rw-r--r--. 1 root root 9789  9月 16 12:12 README.md
    -rw-r--r--. 1 root root 1548  9月 16 12:22 docker-compose.yml
    drwxr-xr-x. 4 root root   31  9月 16 11:18 keys
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/server (main)]
    # cd key
    bash: cd: key: そのようなファイルやディレクトリはありません
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/server (main)]
    # cd keys
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/server/keys (main)]
    # ll
    合計 0
    drwxr-xr-x. 2 root root 6  9月 16 11:18 web
    drwxr-xr-x. 2 root root 6  9月 16 11:18 worker
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/server/keys (main)]
    # ll web/ worker/
    web/:
    合計 0

    worker/:
    合計 0
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/server/keys (main)]
    # docker-compose up -d
    [+] Running 4/4
    ✔ Network server_default     Created                                                                                                                                                                                                                                                                    0.6s 
    ✔ Container server-db-1      Started                                                                                                                                                                                                                                                                    0.1s 
    ✔ Container server-web-1     Started                                                                                                                                                                                                                                                                    0.3s 
    ✔ Container server-worker-1  Started   
    ```


- Concourse WebUIにログインする

    ```sh
    $ fly --target tutorial login --concourse-url http://localhost:8080
    ```

    - 操作
    - `http://localhost:8080/login?fly_port=43269` でホストOSのブラウザにアクセスし、表示されたtokenを貼り付ける
    - ユーザID: `test`、パスワード: `test` とする
    - 上記操作をすると、Concourse CI のWeb UIにログインできる

        ```
        logging in to team 'main'

        navigate to the following URL in your browser:

        http://localhost:8080/login?fly_port=43269

        or enter token manually (input hidden): 
        target saved

    - エラー発生

    ```sh
    fly --target tutorial login --concourse-url http://localhost:8080
    logging in to team 'main'

    could not reach the Concourse server called tutorial:

        Get "http://localhost:8080/api/v1/info": dial tcp [::1]:8080: connect: connection refused

    is the targeted Concourse running? better go catch it lol
    
    ```

    ```sh
    $ fly --target=tutorial login --concourse-url=http://localhost:8080 --username=test --password=test
    ```
    

## Concourse CI の docker-compose.yml を 別のフォルダに移動したら、Concourse CI が動作しなくなったことの考察

- 以下のように、 Concourse CI はフォルダを移動したら起動しなくなった
- コンテナの名前が`concourse-install-xxx`から`server-xxx`に変わっている

    ```sh
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/server (main)]
    # ll 
    合計 16
    -rw-r--r--. 1 root root 9789  9月 16 12:12 README.md
    -rw-r--r--. 1 root root 1548  9月 16 12:22 docker-compose.yml
    drwxr-xr-x. 4 root root   31  9月 16 11:18 keys
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/server (main)]
    # cd key
    bash: cd: key: そのようなファイルやディレクトリはありません
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/server (main)]
    # cd keys
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/server/keys (main)]
    # ll
    合計 0
    drwxr-xr-x. 2 root root 6  9月 16 11:18 web
    drwxr-xr-x. 2 root root 6  9月 16 11:18 worker
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/server/keys (main)]
    # ll web/ worker/
    web/:
    合計 0

    worker/:
    合計 0
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/server/keys (main)]
    # docker-compose up -d
    [+] Running 4/4
    ✔ Network server_default     Created                                                                                                                                                                                                                                                                    0.6s 
    ✔ Container server-db-1      Started                                                                                                                                                                                                                                                                    0.1s 
    ✔ Container server-web-1     Started                                                                                                                                                                                                                                                                    0.3s 
    ✔ Container server-worker-1  Started                                                                                                                                                                                                                                                                    0.1s 
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/server/keys (main)]
    # fly --target tutorial login --concourse-url http://localhost:8080
    logging in to team 'main'

    could not reach the Concourse server called tutorial:

        Get "http://localhost:8080/api/v1/info": dial tcp [::1]:8080: connect: connection refused

    is the targeted Concourse running? better go catch it lol
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/server/keys (main)]
    # curl http://localhost:8080
    curl: (7) Failed connect to localhost:8080; 接続を拒否されました
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/server/keys (main)]
    # docker ps -a
    CONTAINER ID   IMAGE                                COMMAND                   CREATED          STATUS                             PORTS                                   NAMES
    c9496d254eeb   concourse/concourse                  "dumb-init /usr/loca…"   11 minutes ago   Exited (1) 11 minutes ago                                                  server-worker-1
    506d5555212e   concourse/concourse                  "dumb-init /usr/loca…"   11 minutes ago   Exited (1) 11 minutes ago                                                  server-web-1
    d20a4c61d670   postgres                             "docker-entrypoint.s…"   11 minutes ago   Up 11 minutes                      5432/tcp                                server-db-1
    78da09a99cdf   ead0a4a53df8                         "/coredns -conf /etc…"   2 weeks ago      Exited (0) 2 weeks ago                                                     k8s_coredns_coredns-5d78c9869d-pj9gc_kube-system_1ae45187-f869-4fdb-b596-7992cd3e89e5_0
    ea0c2b200dcc   6848d7eda034                         "/usr/local/bin/kube…"   2 weeks ago      Exited (2) 2 weeks ago                                                     k8s_kube-proxy_kube-proxy-j5dzd_kube-system_672b4ee4-5528-4a75-9244-7bb56508ac54_0
    904033446e0d   6e38f40d628d                         "/storage-provisioner"    2 weeks ago      Exited (2) 2 weeks ago                                                     k8s_storage-provisioner_storage-provisioner_kube-system_7ce01bd7-8eb6-4aba-aa0c-b5229e02faf2_0
    dc3cf4bdb98c   registry.k8s.io/pause:3.9            "/pause"                  2 weeks ago      Exited (0) 2 weeks ago                                                     k8s_POD_kube-proxy-j5dzd_kube-system_672b4ee4-5528-4a75-9244-7bb56508ac54_0
    80b93d3702c2   registry.k8s.io/pause:3.9            "/pause"                  2 weeks ago      Exited (0) 2 weeks ago                                                     k8s_POD_coredns-5d78c9869d-pj9gc_kube-system_1ae45187-f869-4fdb-b596-7992cd3e89e5_0
    d0aa15ddddd1   registry.k8s.io/pause:3.9            "/pause"                  2 weeks ago      Exited (0) 2 weeks ago                                                     k8s_POD_storage-provisioner_kube-system_7ce01bd7-8eb6-4aba-aa0c-b5229e02faf2_0
    84fadc0a7b17   86b6af7dd652                         "etcd --advertise-cl…"   2 weeks ago      Exited (0) 2 weeks ago                                                     k8s_etcd_etcd-control-plane.minikube.internal_kube-system_c0cea663baf3558ea4ee6fecf44d4165_0
    2de6e4fb9f2e   f466468864b7                         "kube-controller-man…"   2 weeks ago      Exited (2) 2 weeks ago                                                     k8s_kube-controller-manager_kube-controller-manager-control-plane.minikube.internal_kube-system_e6b85f22bdfbb4cb89ac678030aa9074_0
    60c1016b8c38   e7972205b661                         "kube-apiserver --ad…"   2 weeks ago      Exited (137) 2 weeks ago                                                   k8s_kube-apiserver_kube-apiserver-control-plane.minikube.internal_kube-system_42b79c02d511078b8fe15f3934325ac1_0
    fa7ce578a9af   98ef2570f3cd                         "kube-scheduler --au…"   2 weeks ago      Exited (1) 2 weeks ago                                                     k8s_kube-scheduler_kube-scheduler-control-plane.minikube.internal_kube-system_dacad42d68efb05e47373323414d6ba8_0
    62fb2ac9a505   registry.k8s.io/pause:3.9            "/pause"                  2 weeks ago      Exited (0) 2 weeks ago                                                     k8s_POD_kube-apiserver-control-plane.minikube.internal_kube-system_42b79c02d511078b8fe15f3934325ac1_0
    be8dba37c545   registry.k8s.io/pause:3.9            "/pause"                  2 weeks ago      Exited (0) 2 weeks ago                                                     k8s_POD_kube-scheduler-control-plane.minikube.internal_kube-system_dacad42d68efb05e47373323414d6ba8_0
    625be0d20350   registry.k8s.io/pause:3.9            "/pause"                  2 weeks ago      Exited (0) 2 weeks ago                                                     k8s_POD_kube-controller-manager-control-plane.minikube.internal_kube-system_e6b85f22bdfbb4cb89ac678030aa9074_0
    97eb992dc047   registry.k8s.io/pause:3.9            "/pause"                  2 weeks ago      Exited (0) 2 weeks ago                                                     k8s_POD_etcd-control-plane.minikube.internal_kube-system_c0cea663baf3558ea4ee6fecf44d4165_0
    c3774e09b020   goharbor/harbor-jobservice:v2.8.3    "/harbor/entrypoint.…"   4 weeks ago      Exited (128) 5 days ago                                                    harbor-jobservice
    bb352ac48a4d   goharbor/nginx-photon:v2.8.3         "nginx -g 'daemon of…"   4 weeks ago      Exited (128) 12 days ago           0.0.0.0:80->8080/tcp, :::80->8080/tcp   nginx
    46f7e4c1b4cd   goharbor/harbor-core:v2.8.3          "/harbor/entrypoint.…"   4 weeks ago      Up 50 seconds (health: starting)                                           harbor-core
    43514b955f59   goharbor/harbor-portal:v2.8.3        "nginx -g 'daemon of…"   4 weeks ago      Exited (128) 5 days ago                                                    harbor-portal
    bfbe8d7c247f   goharbor/registry-photon:v2.8.3      "/home/harbor/entryp…"   4 weeks ago      Exited (128) 5 days ago                                                    registry
    72556efa8011   goharbor/redis-photon:v2.8.3         "redis-server /etc/r…"   4 weeks ago      Exited (128) 5 days ago                                                    redis
    b043241d49e3   goharbor/harbor-db:v2.8.3            "/docker-entrypoint.…"   4 weeks ago      Exited (128) 5 days ago                                                    harbor-db
    d976f81103af   goharbor/harbor-registryctl:v2.8.3   "/home/harbor/start.…"   4 weeks ago      Exited (128) 5 days ago                                                    registryctl
    348dddcbb530   goharbor/harbor-log:v2.8.3           "/bin/sh -c /usr/loc…"   4 weeks ago      Up 5 days (healthy)                127.0.0.1:1514->10514/tcp               harbor-log
    ```

- 元のフォルダに戻すと、起動する。（以下）

    ```sh
    # docker ps -a
    CONTAINER ID   IMAGE                                COMMAND                   CREATED          STATUS                             PORTS                                       NAMES
    9c5bb910c9d0   concourse/concourse                  "dumb-init /usr/loca…"   10 seconds ago   Up 5 seconds                                                                   concourse-install-worker-1
    211e63dcd1b9   concourse/concourse                  "dumb-init /usr/loca…"   10 seconds ago   Up 6 seconds                       0.0.0.0:8080->8080/tcp, :::8080->8080/tcp   concourse-install-web-1
    185c80f0b218   postgres                             "docker-entrypoint.s…"   10 seconds ago   Up 8 seconds                       5432/tcp                                    concourse-install-db-1
    78da09a99cdf   ead0a4a53df8                         "/coredns -conf /etc…"   2 weeks ago      Exited (0) 2 weeks ago                                                         k8s_coredns_coredns-5d78c9869d-pj9gc_kube-system_1ae45187-f869-4fdb-b596-7992cd3e89e5_0
    ea0c2b200dcc   6848d7eda034                         "/usr/local/bin/kube…"   2 weeks ago      Exited (2) 2 weeks ago                                                         k8s_kube-proxy_kube-proxy-j5dzd_kube-system_672b4ee4-5528-4a75-9244-7bb56508ac54_0
    904033446e0d   6e38f40d628d                         "/storage-provisioner"    2 weeks ago      Exited (2) 2 weeks ago                                                         k8s_storage-provisioner_storage-provisioner_kube-system_7ce01bd7-8eb6-4aba-aa0c-b5229e02faf2_0
    dc3cf4bdb98c   registry.k8s.io/pause:3.9            "/pause"                  2 weeks ago      Exited (0) 2 weeks ago                                                         k8s_POD_kube-proxy-j5dzd_kube-system_672b4ee4-5528-4a75-9244-7bb56508ac54_0
    80b93d3702c2   registry.k8s.io/pause:3.9            "/pause"                  2 weeks ago      Exited (0) 2 weeks ago                                                         k8s_POD_coredns-5d78c9869d-pj9gc_kube-system_1ae45187-f869-4fdb-b596-7992cd3e89e5_0
    d0aa15ddddd1   registry.k8s.io/pause:3.9            "/pause"                  2 weeks ago      Exited (0) 2 weeks ago                                                         k8s_POD_storage-provisioner_kube-system_7ce01bd7-8eb6-4aba-aa0c-b5229e02faf2_0
    84fadc0a7b17   86b6af7dd652                         "etcd --advertise-cl…"   2 weeks ago      Exited (0) 2 weeks ago                                                         k8s_etcd_etcd-control-plane.minikube.internal_kube-system_c0cea663baf3558ea4ee6fecf44d4165_0
    2de6e4fb9f2e   f466468864b7                         "kube-controller-man…"   2 weeks ago      Exited (2) 2 weeks ago                                                         k8s_kube-controller-manager_kube-controller-manager-control-plane.minikube.internal_kube-system_e6b85f22bdfbb4cb89ac678030aa9074_0
    60c1016b8c38   e7972205b661                         "kube-apiserver --ad…"   2 weeks ago      Exited (137) 2 weeks ago                                                       k8s_kube-apiserver_kube-apiserver-control-plane.minikube.internal_kube-system_42b79c02d511078b8fe15f3934325ac1_0
    fa7ce578a9af   98ef2570f3cd                         "kube-scheduler --au…"   2 weeks ago      Exited (1) 2 weeks ago                                                         k8s_kube-scheduler_kube-scheduler-control-plane.minikube.internal_kube-system_dacad42d68efb05e47373323414d6ba8_0
    62fb2ac9a505   registry.k8s.io/pause:3.9            "/pause"                  2 weeks ago      Exited (0) 2 weeks ago                                                         k8s_POD_kube-apiserver-control-plane.minikube.internal_kube-system_42b79c02d511078b8fe15f3934325ac1_0
    be8dba37c545   registry.k8s.io/pause:3.9            "/pause"                  2 weeks ago      Exited (0) 2 weeks ago                                                         k8s_POD_kube-scheduler-control-plane.minikube.internal_kube-system_dacad42d68efb05e47373323414d6ba8_0
    625be0d20350   registry.k8s.io/pause:3.9            "/pause"                  2 weeks ago      Exited (0) 2 weeks ago                                                         k8s_POD_kube-controller-manager-control-plane.minikube.internal_kube-system_e6b85f22bdfbb4cb89ac678030aa9074_0
    97eb992dc047   registry.k8s.io/pause:3.9            "/pause"                  2 weeks ago      Exited (0) 2 weeks ago                                                         k8s_POD_etcd-control-plane.minikube.internal_kube-system_c0cea663baf3558ea4ee6fecf44d4165_0
    c3774e09b020   goharbor/harbor-jobservice:v2.8.3    "/harbor/entrypoint.…"   4 weeks ago      Exited (128) 5 days ago                                                        harbor-jobservice
    bb352ac48a4d   goharbor/nginx-photon:v2.8.3         "nginx -g 'daemon of…"   4 weeks ago      Exited (128) 12 days ago           0.0.0.0:80->8080/tcp, :::80->8080/tcp       nginx
    46f7e4c1b4cd   goharbor/harbor-core:v2.8.3          "/harbor/entrypoint.…"   4 weeks ago      Up 46 seconds (health: starting)                                               harbor-core
    43514b955f59   goharbor/harbor-portal:v2.8.3        "nginx -g 'daemon of…"   4 weeks ago      Exited (128) 5 days ago                                                        harbor-portal
    bfbe8d7c247f   goharbor/registry-photon:v2.8.3      "/home/harbor/entryp…"   4 weeks ago      Exited (128) 5 days ago                                                        registry
    72556efa8011   goharbor/redis-photon:v2.8.3         "redis-server /etc/r…"   4 weeks ago      Exited (128) 5 days ago                                                        redis
    b043241d49e3   goharbor/harbor-db:v2.8.3            "/docker-entrypoint.…"   4 weeks ago      Exited (128) 5 days ago                                                        harbor-db
    d976f81103af   goharbor/harbor-registryctl:v2.8.3   "/home/harbor/start.…"   4 weeks ago      Exited (128) 5 days ago                                                        registryctl
    348dddcbb530   goharbor/harbor-log:v2.8.3           "/bin/sh -c /usr/loc…"   4 weeks ago      Up 5 days (healthy)                127.0.0.1:1514->10514/tcp                   harbor-log
    [root@control-plane ~/concourse-install (main)]
    ```

- 原因は、`docker-compose.yml`と一緒に、`keys` フォルダをコピーしなかったことが考えられる
- そこで、`keys` フォルダを 公式のリポジトリ のものに置換え、`generate` を実行してみる


    - 公式のリポジトリのフォルダ

        ```sh
        # ll ~/concourse-docker/
        合計 32
        -rw-r--r--. 1 root root   863  8月 31 20:18 Dockerfile
        -rw-r--r--. 1 root root 11324  8月 31 20:18 LICENSE.md
        -rw-r--r--. 1 root root   593  8月 31 20:18 NOTICE.md
        -rw-r--r--. 1 root root  2992  8月 31 20:18 README.md
        drwxr-xr-x. 2 root root    22  8月 31 20:18 bin
        drwxr-xr-x. 2 root root    29  8月 31 20:18 ci
        -rw-r--r--. 1 root root  1323  8月 31 20:18 docker-compose.yml
        -rwxr-xr-x. 1 root root  1159  8月 31 20:18 entrypoint.sh
        drwxr-xr-x. 4 root root    47  8月 31 20:18 keys
        ```

    - `keys`フォルダ下に`generate`がある。

        ```sh
        [root@control-plane ~/concourse-install (main)]
        # ll ~/concourse-docker/keys/
        合計 4
        -rwxr-xr-x. 1 root root 617  8月 31 20:18 generate
        drwxr-xr-x. 2 root root  22  8月 31 20:18 web
        drwxr-xr-x. 2 root root  22  8月 31 20:18 worker
        [root@control-plane ~/concourse-install (main)]
        ````
    
    - 今回作成し他フォルダの中身 `keys`フォルダ下に`generate`がない

        ```sh
        # cd ~/cicd-repo-for-manifesto/concourse/server/
        [root@control-plane ~/cicd-repo-for-manifesto/concourse/server (main)]
        # ll
        合計 36
        -rw-r--r--. 1 root root 28850  9月 16 13:20 README.md
        -rw-r--r--. 1 root root  1548  9月 16 12:22 docker-compose.yml
        drwxr-xr-x. 4 root root    31  9月 16 11:18 keys
        [root@control-plane ~/cicd-repo-for-manifesto/concourse/server (main)]
        # ll keys/
        合計 0
        drwxr-xr-x. 2 root root 6  9月 16 11:18 web
        drwxr-xr-x. 2 root root 6  9月 16 11:18 worker
        ```

- まず、実行中の Concord CI を停止する

    ```sh
    # docker-compose down
    [+] Running 4/4
    ✔ Container concourse-install-worker-1  Removed                                                                                                                                                    10.4s 
    ✔ Container concourse-install-web-1     Removed                                                                                                                                                    10.6s 
    ✔ Container concourse-install-db-1      Removed                                                                                                                                                     0.5s 
    ✔ Network concourse-install_default     Removed 
    ```

    ```sh
    # docker ps -a | grep conc | wc -l
    0
    ```

- 今回作成したファルダの`keys/`を置換える

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/server/
    ```

    ```sh
    $ cp -r  ~/concourse-docker/keys/ .
    ```

    ```sh
    $ cd ./keys
    ```

    ```sh
    $ ll
    合計 4
    -rwxr-xr-x. 1 root root 617  9月 16 22:20 generate
    drwxr-xr-x. 2 root root  22  9月 16 22:20 web
    drwxr-xr-x. 2 root root  22  9月 16 22:20 worker
    ```

    ```sh
    $  .  generate
    ```

    - 結果
    - コンテナイメージのpullが行われず、keyの値のみ更新された模様

        ```sh
        wrote private key to /keys/session_signing_key
        wrote private key to /keys/tsa_host_key
        wrote ssh public key to /keys/tsa_host_key.pub
        wrote private key to /keys/worker_key
        wrote ssh public key to /keys/worker_key.pub
        ```
- `bin/` フォルダに移動している

    ```sh
    $ pwd
    /bin
    ```

- Concourse CI を起動


    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/server/
    ```

    ```sh
    # docker-compose up -d
    [+] Running 4/4
    ✔ Network server_default     Created                                                                                      0.5s 
    ✔ Container server-db-1      Started                                                                                      0.2s 
    ✔ Container server-web-1     Started                                                                                      0.2s 
    ✔ Container server-worker-1  Started    
    ```

    ```sh
    # docker ps -a | grep -e 'server-'
    2aadcef49b63   concourse/concourse                  "dumb-init /usr/loca…"   9 minutes ago   Exited (1) 9 minutes ago                                                   server-worker-1
    69517cd30d04   concourse/concourse                  "dumb-init /usr/loca…"   9 minutes ago   Exited (1) 9 minutes ago                                                   server-web-1
    536c9f97975b   postgres                             "docker-entrypoint.s…"   9 minutes ago   Up 9 minutes                       5432/tcp                                server-db-1
    60c1016b8c38   e7972205b661                         "kube-apiserver --ad…"   2 weeks ago     Exited (137) 2 weeks ago                                                   k8s_kube-apiserver_kube-apiserver-control-plane.minikube.internal_kube-system_42b79c02d511078b8fe15f3934325ac1_0
    62fb2ac9a505   registry.k8s.io/pause:3.9            "/pause"                  2 weeks ago     Exited (0) 2 weeks ago                                                     k8s_POD_kube-apiserver-control-plane.minikube.internal_kube-system_42b79c02d511078b8fe15f3934325ac1_0
    ```

</del>


- フォルダを移動すると上手く行かない。
- 【結論】とりあえず、現状は、Concourse CI の `docker-compose.yml`と`keys/`は、`~/concourse-install /`にあり、WebUIのURLは、 `http://localhost:8080` にある前提で作業を進める。

- 【現状の課題】Concourse CI は`keys/generate`を実行後、インストールフォルダを変更する方法を確認する。

- 【現状の課題】Concourse CI のWebUIのURLを `http://localhost:8080` 以外にする方法を確認する。 


### Concourse CI の停止

- これまでの設定で起動していた Concourse CI を停止する

    ```sh
    $ docker-compose down
    [+] Running 4/4
    ✔ Container concourse-install-worker-1  Removed                                                                                                                                                         10.3s 
    ✔ Container concourse-install-web-1     Removed                                                                                                                                                         10.4s 
    ✔ Container concourse-install-db-1      Removed                                                                                                                                                          0.5s 
    ✔ Network concourse-install_default     Removed 
    ```

### Concourse CI を起動する

- 以下のコマンドを実行

    ```sh
    $ cd ~/concourse-install/
    ```

    ```sh
     ll
    合計 180
    -rw-r--r--. 1 root root 164318  9月  9 23:26 README.md
    -rw-r--r--. 1 root root   2021  9月  9 23:26 credentials.yml
    -rw-r--r--. 1 root root   1548  9月 10 14:12 docker-compose.yml
    -rw-r--r--. 1 root root   1548  9月 10 14:11 docker-compose.yml_old
    drwxr-xr-x. 2 root root     45  9月  9 23:26 imgs
    drwxr-xr-x. 4 root root     47  9月  9 23:26 keys
    -rw-r--r--. 1 root root   2985  9月  9 23:26 pipeline.yml
    drwxr-xr-x. 4 root root     96  9月 10 10:39 tutorials
    ```

    ```sh
    $ docker-compose up -d
    [+] Running 4/4
    ✔ Network concourse-install_default     Created                                                                                                                                                          0.2s 
    ✔ Container concourse-install-db-1      Started                                                                                                                                                          0.2s 
    ✔ Container concourse-install-web-1     Started                                                                                                                                                          0.2s 
    ✔ Container concourse-install-worker-1  Started 
    ```

- 起動成功

    ```sh
    $ docker ps -a | grep conc
    4b95c7837820   concourse/concourse                  "dumb-init /usr/loca…"   About a minute ago   Up About a minute                                                              concourse-install-worker-1
    4b6b4fb1f576   concourse/concourse                  "dumb-init /usr/loca…"   About a minute ago   Up About a minute                  0.0.0.0:8080->8080/tcp, :::8080->8080/tcp   concourse-install-web-1
    fb41ea9837d9   postgres                             "docker-entrypoint.s…"   About a minute ago   Up About a minute                  5432/tcp                                    concourse-install-db-1
    ```

### Concourse WebUIにログインする

- Concourse WebUIにログインする

    ```sh
    $ fly --target tutorial login --concourse-url http://localhost:8080
    ```

    - 操作
    - `http://localhost:8080/login?fly_port=43269` でホストOSのブラウザにアクセスし、表示されたtokenを貼り付ける
    - ユーザID: `test`、パスワード: `test` とする
    - 上記操作をすると、Concourse CI のWeb UIにログインできる

        ```
        logging in to team 'main'

        navigate to the following URL in your browser:

        http://localhost:8080/login?fly_port=43269

        or enter token manually (input hidden): 
        target saved

### Concurse CI からGitHubに書込むパイプラインの動作確認を行う

- パイプラインのYAMLをコピー

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/pipline/
    ```

    ```sh
    $ cp ~/concourse-semver-test/tutorials/miscellaneous/versions-and-buildnumbers/pipeline-bump-soft-version.yml .
    ```

    ```sh
    $  ll
    合計 4
    -rw-r--r--. 1 root root 3658  9月 17 00:07 pipeline-bump-soft-version.yml
    ```

- パイプラインを削除する

    ```sh
    $ fly -t tutorial destroy-pipeline -p bump-soft-minor-version -n
    ```

- パイプラインを作成

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/pipline/
    ```

    ```sh
    $ fly -t tutorial set-pipeline -p bump-soft-minor-version -c pipeline-bump-soft-version.yml -v bump-type=minor -n
    ```

    - 結果

        ```sh
        resources:
        resource git-repository has been added:
        + name: git-repository
        + source:
        +   branch: main
        +   private_key: ((private-key))
        +   uri: git@github.com:moriyamaES/semver-test.git
        + type: git
        
        jobs:
        job bump-version has been added:
        + name: bump-version
        + plan:
        + - get: git-repository
        + - config:
        +     image_resource:
        +       name: ""
        +       source:
        +         repository: getourneau/alpine-bash-git
        +       type: docker-image
        +     inputs:
        +     - name: git-repository
        +     outputs:
        +     - name: git-repository
        +     params:
        +       BUMP_TYPE: minor
        +     platform: linux
        +     run:
        +       args:
        +       - -exc
        +       - |2
        + 
        +         # この時点ではconcorseがgit cloneを実行してるため、git cloneの実行は不要。
        +         # gitのローカルリポジトリのディレクトリに移動
        +         cd git-repository
        + 
        +         # 現在のバージョンを取得
        +         current_version=$(cat ./version/number)
        + 
        +         # バージョンをバンプするタイプを指定
        +         BUMP_TYPE=${BUMP_TYPE:-"major"}  # デフォルトはメジャーバージョンをバンプ
        + 
        +         # current_version が空文字列の場合
        +         if [ "$current_version" = "" ]; then
        +             # 適切な初期バージョンを設定
        +             if [ "$BUMP_TYPE" = "major" ]; then
        +               new_version="1.0.0"
        +             elif [ "$BUMP_TYPE" = "minor" ]; then
        +               new_version="0.1.0"
        +             elif [ "$BUMP_TYPE" = "patch" ]; then
        +               new_version="0.0.1"
        +             else
        +               echo "Invalid bump_type specified."
        +               exit 1
        +             fi
        +         else
        +           # バージョンをバンプする
        +           IFS_SAVE=$IFS
        +           IFS='.'
        +           set $current_version
        +           IFS=$IFS_SAVE
        +           major="$1"
        +           minor="$2"
        +           patch="$3"
        +           if [ "$BUMP_TYPE" = "major" ]; then
        +             major=$((major + 1))
        +             minor=0
        +             patch=0
        +           elif [ "$BUMP_TYPE" = "minor" ]; then
        +             minor=$((minor + 1))
        +             patch=0
        +           elif [ "$BUMP_TYPE" = "patch" ]; then
        +             patch=$((patch + 1))
        +           fi
        +           new_version="$major.$minor.$patch"
        +         fi
        + 
        +         # 新しいバージョンをファイルに書き込む
        +         echo "$new_version" > ./version/number
        +         cat ./version/number
        + 
        +         # コミットしタグを付加する
        +         git config --global user.email "concourse@local" # メールアドレスは必須（ユーザ名は任意）
        +         git add ./version/number
        +         git commit -m "Bump version to v$new_version"
        +         git tag v$new_version
        +       path: /bin/sh
        +   task: bump-timestamp-file
        + - params:
        +     repository: git-repository
        +   put: git-repository
        
        pipeline name: bump-soft-minor-version

        pipeline created!
        you can view your pipeline here: http://localhost:8080/teams/main/pipelines/bump-soft-minor-version

        the pipeline is currently paused. to unpause, either:
        - run the unpause-pipeline command:
            fly -t tutorial unpause-pipeline -p bump-soft-minor-version
        - click play next to the pipeline in the web u
        ```


- リソースのチェク

    ```sh
    $ fly -t tutorial check-resource -r bump-soft-minor-version/git-repository
    ```

        - 結果

        ```sh
        checking bump-soft-minor-version/git-repository in build 1
        initializing check: git-repository
        selected worker: 4b95c7837820
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        Cloning into '/tmp/git-resource-repo-cache'...
        succeeded
        ```

- パイプラインの実行

    ```sh
    $ fly -t tutorial unpause-pipeline -p bump-soft-minor-version
    unpaused 'bump-soft-minor-version'
    ```

    ```sh
    $ fly -t tutorial trigger-job -j bump-soft-minor-version/bump-version -w
    ```

    - 結果

        ```sh
        started bump-soft-minor-version/bump-version #1

        selected worker: 4b95c7837820
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        Cloning into '/tmp/build/get'...
        3817200 Bump version to v0.1.0
        initializing
        initializing check: image
        selected worker: 4b95c7837820
        selected worker: 4b95c7837820
        waiting for docker to come up...
        Pulling getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7...
        docker.io/getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7: Pulling from getourneau/alpine-bash-git
        4fe2ade4980c: Pulling fs layer
        03c196859ec8: Pulling fs layer
        720d2de11875: Pulling fs layer
        4fe2ade4980c: Verifying Checksum
        4fe2ade4980c: Download complete
        03c196859ec8: Verifying Checksum
        03c196859ec8: Download complete
        4fe2ade4980c: Pull complete
        720d2de11875: Verifying Checksum
        720d2de11875: Download complete
        03c196859ec8: Pull complete
        720d2de11875: Pull complete
        Digest: sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7
        Status: Downloaded newer image for getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7
        docker.io/getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7

        Successfully pulled getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7.

        selected worker: 4b95c7837820
        running /bin/sh -exc 
        # この時点ではconcorseがgit cloneを実行してるため、git cloneの実行は不要。
        # gitのローカルリポジトリのディレクトリに移動
        cd git-repository

        # 現在のバージョンを取得
        current_version=$(cat ./version/number)

        # バージョンをバンプするタイプを指定
        BUMP_TYPE=${BUMP_TYPE:-"major"}  # デフォルトはメジャーバージョンをバンプ

        # current_version が空文字列の場合
        if [ "$current_version" = "" ]; then
            # 適切な初期バージョンを設定
            if [ "$BUMP_TYPE" = "major" ]; then
            new_version="1.0.0"
            elif [ "$BUMP_TYPE" = "minor" ]; then
            new_version="0.1.0"
            elif [ "$BUMP_TYPE" = "patch" ]; then
            new_version="0.0.1"
            else
            echo "Invalid bump_type specified."
            exit 1
            fi
        else
        # バージョンをバンプする
        IFS_SAVE=$IFS
        IFS='.'
        set $current_version
        IFS=$IFS_SAVE
        major="$1"
        minor="$2"
        patch="$3"
        if [ "$BUMP_TYPE" = "major" ]; then
            major=$((major + 1))
            minor=0
            patch=0
        elif [ "$BUMP_TYPE" = "minor" ]; then
            minor=$((minor + 1))
            patch=0
        elif [ "$BUMP_TYPE" = "patch" ]; then
            patch=$((patch + 1))
        fi
        new_version="$major.$minor.$patch"
        fi

        # 新しいバージョンをファイルに書き込む
        echo "$new_version" > ./version/number
        cat ./version/number

        # コミットしタグを付加する
        git config --global user.email "concourse@local" # メールアドレスは必須（ユーザ名は任意）
        git add ./version/number
        git commit -m "Bump version to v$new_version"
        git tag v$new_version

        + cd git-repository
        + cat ./version/number
        + current_version=0.1.0
        + BUMP_TYPE=minor
        + '[' 0.1.0 '='  ]
        + IFS_SAVE=' 
        '
        + IFS=.
        + set 0 1 0
        + IFS=' 
        '
        + major=0
        + minor=1
        + patch=0
        + '[' minor '=' major ]
        + '[' minor '=' minor ]
        + minor=2
        + patch=0
        + new_version=0.2.0
        + echo 0.2.0
        + cat ./version/number
        0.2.0
        + git config --global user.email concourse@local
        + git add ./version/number
        + git commit -m 'Bump version to v0.2.0'
        [detached HEAD 6dd38ee] Bump version to v0.2.0
        1 file changed, 1 insertion(+), 1 deletion(-)
        + git tag v0.2.0
        selected worker: 4b95c7837820
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        To github.com:moriyamaES/semver-test.git
        3817200..6dd38ee  HEAD -> main
        * [new tag]         v0.2.0 -> v0.2.0
        selected worker: 4b95c7837820
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        Cloning into '/tmp/build/get'...
        6dd38ee Bump version to v0.2.0
        succeeded
        ```

- 成功 ！！

## Concourse CI によるバージョン番号の書込み先をソースコード・リポジトリに変更する

### パイプラインYAMLのファイル名、リソース名、バージョンの保存先フォルダ名を変更する

- 以下のコマンドを実行する

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/pipline
    ```

    ```sh
    $ cp pipeline-bump-soft-version.yml pipeline-bump-source-code-version.yml
    ```

    ```sh
    # cat pipeline-bump-source-code-version.yml 
    ---
    resources:
    - name: version-bump-repository
        type: git
        source:
        branch: main
        # sshで認証するため、uriはsshのuriに設定する必要がある(httpsだと正常動作しない）
        uri: git@github.com:moriyamaES/cicd-repo-for-source-code.git
        # GitHubに接続するための秘密鍵はVaultで管理
        private_key: ((private-key))
    jobs:
    - name: bump-version
        plan:
        - get: version-bump-repository
        - task: bump-version
            config:
            platform: linux
            image_resource:
                type: docker-image
                # bashとgitが実行できるコンテナをpull
                source: {repository: getourneau/alpine-bash-git}
            # nputsとoutputsは、同じ名前にしないと正常動作しない模様
            inputs:
                - name: version-bump-repository
            outputs:
                - name: version-bump-repository
            run:
                path: /bin/sh
                args:
                - -exc
                - |

                    # この時点ではconcorseがgit cloneを実行してるため、git cloneの実行は不要。
                    # gitのローカルリポジトリのディレクトリに移動
                    cd version-bump-repository

                    # 現在のバージョンを取得
                    current_version=$(cat ./.version/number)
                    
                    # バージョンをバンプするタイプを指定
                    BUMP_TYPE=${BUMP_TYPE:-"major"}  # デフォルトはメジャーバージョンをバンプ
                    
                    # current_version が空文字列の場合
                    if [ "$current_version" = "" ]; then
                        # 適切な初期バージョンを設定
                        if [ "$BUMP_TYPE" = "major" ]; then
                        new_version="1.0.0"
                        elif [ "$BUMP_TYPE" = "minor" ]; then
                        new_version="0.1.0"
                        elif [ "$BUMP_TYPE" = "patch" ]; then
                        new_version="0.0.1"
                        else
                        echo "Invalid bump_type specified."
                        exit 1
                        fi
                    else
                    # バージョンをバンプする
                    IFS_SAVE=$IFS
                    IFS='.'
                    set $current_version
                    IFS=$IFS_SAVE
                    major="$1"
                    minor="$2"
                    patch="$3"
                    if [ "$BUMP_TYPE" = "major" ]; then
                        major=$((major + 1))
                        minor=0
                        patch=0
                    elif [ "$BUMP_TYPE" = "minor" ]; then
                        minor=$((minor + 1))
                        patch=0
                    elif [ "$BUMP_TYPE" = "patch" ]; then
                        patch=$((patch + 1))
                    fi
                    new_version="$major.$minor.$patch"
                    fi
            
                    # 新しいバージョンをファイルに書き込む
                    echo "$new_version" > ./.version/number
                    cat ./.version/number

                    # コミットしタグを付加する
                    git config --global user.email "concourse@local" # メールアドレスは必須（ユーザ名は任意）
                    git add ./.version/number
                    git commit -m "Bump version to v$new_version"
                    git tag v$new_version
            params:
                BUMP_TYPE: ((bump-type))

        # このPUTで、ローカルリポジトリからリポジトリへのpushを実行するため、git pushの実行は不要。
        - put: version-bump-repository
            params:
            repository: version-bump-repository
    ```

- パイプラインを削除する

    ```sh
    $ fly -t tutorial destroy-pipeline -p bump-source-code-minor-version -n
    ```

- パイプラインを作成

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/pipline
    ```

    ```sh
    $ fly -t tutorial set-pipeline -p bump-source-code-minor-version -c pipeline-bump-source-code-version.yml -v bump-type=minor -n
    ```

    - 結果

        ```sh
        resources:
        resource version-bump-repository has been added:
        + name: version-bump-repository
        + source:
        +   branch: main
        +   private_key: ((private-key))
        +   uri: git@github.com:moriyamaES/cicd-repo-for-source-code.git
        + type: git
        
        jobs:
        job bump-version has been added:
        + name: bump-version
        + plan:
        + - get: version-bump-repository
        + - config:
        +     image_resource:
        +       name: ""
        +       source:
        +         repository: getourneau/alpine-bash-git
        +       type: docker-image
        +     inputs:
        +     - name: version-bump-repository
        +     outputs:
        +     - name: version-bump-repository
        +     params:
        +       BUMP_TYPE: minor
        +     platform: linux
        +     run:
        +       args:
        +       - -exc
        +       - |2
        + 
        +         # この時点ではconcorseがgit cloneを実行してるため、git cloneの実行は不要。
        +         # gitのローカルリポジトリのディレクトリに移動
        +         cd version-bump-repository
        + 
        +         # 現在のバージョンを取得
        +         current_version=$(cat ./.version/number)
        + 
        +         # バージョンをバンプするタイプを指定
        +         BUMP_TYPE=${BUMP_TYPE:-"major"}  # デフォルトはメジャーバージョンをバンプ
        + 
        +         # current_version が空文字列の場合
        +         if [ "$current_version" = "" ]; then
        +             # 適切な初期バージョンを設定
        +             if [ "$BUMP_TYPE" = "major" ]; then
        +               new_version="1.0.0"
        +             elif [ "$BUMP_TYPE" = "minor" ]; then
        +               new_version="0.1.0"
        +             elif [ "$BUMP_TYPE" = "patch" ]; then
        +               new_version="0.0.1"
        +             else
        +               echo "Invalid bump_type specified."
        +               exit 1
        +             fi
        +         else
        +           # バージョンをバンプする
        +           IFS_SAVE=$IFS
        +           IFS='.'
        +           set $current_version
        +           IFS=$IFS_SAVE
        +           major="$1"
        +           minor="$2"
        +           patch="$3"
        +           if [ "$BUMP_TYPE" = "major" ]; then
        +             major=$((major + 1))
        +             minor=0
        +             patch=0
        +           elif [ "$BUMP_TYPE" = "minor" ]; then
        +             minor=$((minor + 1))
        +             patch=0
        +           elif [ "$BUMP_TYPE" = "patch" ]; then
        +             patch=$((patch + 1))
        +           fi
        +           new_version="$major.$minor.$patch"
        +         fi
        + 
        +         # 新しいバージョンをファイルに書き込む
        +         echo "$new_version" > ./.version/number
        +         cat ./.version/number
        + 
        +         # コミットしタグを付加する
        +         git config --global user.email "concourse@local" # メールアドレスは必須（ユーザ名は任意）
        +         git add ./.version/number
        +         git commit -m "Bump version to v$new_version"
        +         git tag v$new_version
        +       path: /bin/sh
        +   task: bump-version
        + - params:
        +     repository: version-bump-repository
        +   put: version-bump-repository
        
        pipeline name: bump-source-code-minor-version

        pipeline created!
        you can view your pipeline here: http://localhost:8080/teams/main/pipelines/bump-source-code-minor-version

        the pipeline is currently paused. to unpause, either:
        - run the unpause-pipeline command:
            fly -t tutorial unpause-pipeline -p bump-source-code-minor-version
        - click play next to the pipeline in the web ui
        ```

- リソースのチェク

    ```sh
    $ fly -t tutorial check-resource -r bump-source-code-minor-version/version-bump-repository
    ```

    - 結果

        ```sh
        checking bump-source-code-minor-version/version-bump-repository in build 67
        initializing check: version-bump-repository
        selected worker: 4b95c7837820
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        Cloning into '/tmp/git-resource-repo-cache'...
        succeeded
        ```

- パイプラインの実行

    ```sh
    $ fly -t tutorial unpause-pipeline -p bump-source-code-minor-version
    unpaused 'bump-source-code-minor-version'
    ```

    ```sh
    $ fly -t tutorial trigger-job -j bump-source-code-minor-version/bump-version -w
    ```

    - 結果 (エラーになった)

        ```sh
        started bump-source-code-minor-version/bump-version #1

        selected worker: 4b95c7837820
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        Cloning into '/tmp/build/get'...
        b2881f1 Remane version dir
        initializing
        initializing check: image
        selected worker: 4b95c7837820
        selected worker: 4b95c7837820
        waiting for docker to come up...
        Pulling getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7...
        docker.io/getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7: Pulling from getourneau/alpine-bash-git
        4fe2ade4980c: Pulling fs layer
        03c196859ec8: Pulling fs layer
        720d2de11875: Pulling fs layer
        4fe2ade4980c: Verifying Checksum
        4fe2ade4980c: Download complete
        720d2de11875: Verifying Checksum
        720d2de11875: Download complete
        4fe2ade4980c: Pull complete
        03c196859ec8: Verifying Checksum
        03c196859ec8: Download complete
        03c196859ec8: Pull complete
        720d2de11875: Pull complete
        Digest: sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7
        Status: Downloaded newer image for getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7
        docker.io/getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7

        Successfully pulled getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7.

        selected worker: 4b95c7837820
        running /bin/sh -exc 
        # この時点ではconcorseがgit cloneを実行してるため、git cloneの実行は不要。
        # gitのローカルリポジトリのディレクトリに移動
        cd version-bump-repository

        # 現在のバージョンを取得
        current_version=$(cat ./.version/number)

        # バージョンをバンプするタイプを指定
        BUMP_TYPE=${BUMP_TYPE:-"major"}  # デフォルトはメジャーバージョンをバンプ

        # current_version が空文字列の場合
        if [ "$current_version" = "" ]; then
            # 適切な初期バージョンを設定
            if [ "$BUMP_TYPE" = "major" ]; then
            new_version="1.0.0"
            elif [ "$BUMP_TYPE" = "minor" ]; then
            new_version="0.1.0"
            elif [ "$BUMP_TYPE" = "patch" ]; then
            new_version="0.0.1"
            else
            echo "Invalid bump_type specified."
            exit 1
            fi
        else
        # バージョンをバンプする
        IFS_SAVE=$IFS
        IFS='.'
        set $current_version
        IFS=$IFS_SAVE
        major="$1"
        minor="$2"
        patch="$3"
        if [ "$BUMP_TYPE" = "major" ]; then
            major=$((major + 1))
            minor=0
            patch=0
        elif [ "$BUMP_TYPE" = "minor" ]; then
            minor=$((minor + 1))
            patch=0
        elif [ "$BUMP_TYPE" = "patch" ]; then
            patch=$((patch + 1))
        fi
        new_version="$major.$minor.$patch"
        fi

        # 新しいバージョンをファイルに書き込む
        echo "$new_version" > ./.version/number
        cat ./.version/number

        # コミットしタグを付加する
        git config --global user.email "concourse@local" # メールアドレスは必須（ユーザ名は任意）
        git add ./.version/number
        git commit -m "Bump version to v$new_version"
        git tag v$new_version

        + cd version-bump-repository
        + cat ./.version/number
        cat: can't open './.version/number': No such file or directory
        + current_version=
        failed
        ```
    - 隠しフォルダ`.version/`は更新できない？ → いやできるかも

    - 隠しフォルダ`.version/`を通常のフォルダに戻す　→ いや、隠しフォルダ`.version/`を使用する


<del>

### パイプラインYAMLのファイル名、リソース名、バージョンの保存先フォルダ名を変更する

- 以下のコマンドを実行する

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/pipline
    ```

- 変更点は以下

    ```sh
    $ git log --graph --decorate=short --oneline | head -2
    * ea68b76 (HEAD -> main, origin/main, origin/HEAD) Update pipline
    * 2db222d Update pipline
    ```

    ```sh
    $ git diff 2db222d ea68b76 --name-only 
    concourse/pipline/pipeline-bump-source-code-version.yml
    ```

    ```sh
    $ git diff 2db222d ea68b76 -- ./concourse/pipline/pipeline-bump-source-code-version.yml 

    ```

    - 結果
    
        ```diff
        diff --git a/concourse/pipline/pipeline-bump-source-code-version.yml b/concourse/pipline/pipeline-bump-source-code-version.yml
        index c67054e..44eafbb 100644
        --- a/concourse/pipline/pipeline-bump-source-code-version.yml
        +++ b/concourse/pipline/pipeline-bump-source-code-version.yml
        @@ -1,6 +1,6 @@
        ---
        resources:
        -  - name: version-bump-repository
        +  - name: repository-with-a-version-bump
            type: git
            source:
            branch: main
        @@ -11,7 +11,7 @@ resources:
        jobs:
        - name: bump-version
            plan:
        -      - get: version-bump-repository
        +      - get: repository-with-a-version-bump
            - task: bump-version
                config:
                platform: linux
        @@ -21,9 +21,9 @@ jobs:
                    source: {repository: getourneau/alpine-bash-git}
                # nputsとoutputsは、同じ名前にしないと正常動作しない模様
                inputs:
        -            - name: version-bump-repository
        +            - name: repository-with-a-version-bump
                outputs:
        -            - name: version-bump-repository
        +            - name: repository-with-a-version-bump
                run:
                    path: /bin/sh
                    args:
        @@ -32,10 +32,10 @@ jobs:
        
                        # この時点ではconcorseがgit cloneを実行してるため、git cloneの実行は不要。
                        # gitのローカルリポジトリのディレクトリに移動
        -                cd version-bump-repository
        +                cd repository-with-a-version-bump
        
                        # 現在のバージョンを取得
        -                current_version=$(cat ./.version/number)
        +                current_version=$(cat ./version/number)
                        
                        # バージョンをバンプするタイプを指定
                        BUMP_TYPE=${BUMP_TYPE:-"major"}  # デフォルトはメジャーバージョンをバンプ
        @@ -76,18 +76,18 @@ jobs:
                        fi
                
                        # 新しいバージョンをファイルに書き込む
        -                echo "$new_version" > ./.version/number
        -                cat ./.version/number
        +                echo "$new_version" > ./version/number
        +                cat ./version/number
        
                        # コミットしタグを付加する
                        git config --global user.email "concourse@local" # メールアドレスは必須（ユーザ名は任意）
        -                git add ./.version/number
        +                git add ./version/number
                        git commit -m "Bump version to v$new_version"
                        git tag v$new_version
                params:
                    BUMP_TYPE: ((bump-type))
        
            # このPUTで、ローカルリポジトリからリポジトリへのpushを実行するため、git pushの実行は不要。
        -      - put: version-bump-repository
        +      - put: repository-with-a-version-bump
                params:
        -          repository: version-bump-repository
        +          repository: repository-with-a-version-bump
        
        ```

- 変更後

    ```sh
    # cat ./concourse/pipline/pipeline-bump-source-code-version.yml 
    ---
    resources:
    - name: repository-with-a-version-bump
        type: git
        source:
        branch: main
        # sshで認証するため、uriはsshのuriに設定する必要がある(httpsだと正常動作しない）
        uri: git@github.com:moriyamaES/cicd-repo-for-source-code.git
        # GitHubに接続するための秘密鍵はVaultで管理
        private_key: ((private-key))
    jobs:
    - name: bump-version
        plan:
        - get: repository-with-a-version-bump
        - task: bump-version
            config:
            platform: linux
            image_resource:
                type: docker-image
                # bashとgitが実行できるコンテナをpull
                source: {repository: getourneau/alpine-bash-git}
            # nputsとoutputsは、同じ名前にしないと正常動作しない模様
            inputs:
                - name: repository-with-a-version-bump
            outputs:
                - name: repository-with-a-version-bump
            run:
                path: /bin/sh
                args:
                - -exc
                - |

                    # この時点ではconcorseがgit cloneを実行してるため、git cloneの実行は不要。
                    # gitのローカルリポジトリのディレクトリに移動
                    cd repository-with-a-version-bump

                    # 現在のバージョンを取得
                    current_version=$(cat ./version/number)
                    
                    # バージョンをバンプするタイプを指定
                    BUMP_TYPE=${BUMP_TYPE:-"major"}  # デフォルトはメジャーバージョンをバンプ
                    
                    # current_version が空文字列の場合
                    if [ "$current_version" = "" ]; then
                        # 適切な初期バージョンを設定
                        if [ "$BUMP_TYPE" = "major" ]; then
                        new_version="1.0.0"
                        elif [ "$BUMP_TYPE" = "minor" ]; then
                        new_version="0.1.0"
                        elif [ "$BUMP_TYPE" = "patch" ]; then
                        new_version="0.0.1"
                        else
                        echo "Invalid bump_type specified."
                        exit 1
                        fi
                    else
                    # バージョンをバンプする
                    IFS_SAVE=$IFS
                    IFS='.'
                    set $current_version
                    IFS=$IFS_SAVE
                    major="$1"
                    minor="$2"
                    patch="$3"
                    if [ "$BUMP_TYPE" = "major" ]; then
                        major=$((major + 1))
                        minor=0
                        patch=0
                    elif [ "$BUMP_TYPE" = "minor" ]; then
                        minor=$((minor + 1))
                        patch=0
                    elif [ "$BUMP_TYPE" = "patch" ]; then
                        patch=$((patch + 1))
                    fi
                    new_version="$major.$minor.$patch"
                    fi
            
                    # 新しいバージョンをファイルに書き込む
                    echo "$new_version" > ./version/number
                    cat ./version/number

                    # コミットしタグを付加する
                    git config --global user.email "concourse@local" # メールアドレスは必須（ユーザ名は任意）
                    git add ./version/number
                    git commit -m "Bump version to v$new_version"
                    git tag v$new_version
            params:
                BUMP_TYPE: ((bump-type))

        # このPUTで、ローカルリポジトリからリポジトリへのpushを実行するため、git pushの実行は不要。
        - put: repository-with-a-version-bump
            params:
            repository: repository-with-a-version-bump
    ```

- パイプラインを削除する

    ```sh
    $ fly -t tutorial destroy-pipeline -p bump-source-code-minor-version -n
    ```

- パイプラインを作成

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/pipline
    ```

    ```sh
    $ fly -t tutorial set-pipeline -p bump-source-code-minor-version -c pipeline-bump-source-code-version.yml -v bump-type=minor -n
    ```

    - 結果

        ```sh
        resources:
        resource repository-with-a-version-bump has been added:
        + name: repository-with-a-version-bump
        + source:
        +   branch: main
        +   private_key: ((private-key))
        +   uri: git@github.com:moriyamaES/cicd-repo-for-source-code.git
        + type: git
        
        jobs:
        job bump-version has been added:
        + name: bump-version
        + plan:
        + - get: repository-with-a-version-bump
        + - config:
        +     image_resource:
        +       name: ""
        +       source:
        +         repository: getourneau/alpine-bash-git
        +       type: docker-image
        +     inputs:
        +     - name: repository-with-a-version-bump
        +     outputs:
        +     - name: repository-with-a-version-bump
        +     params:
        +       BUMP_TYPE: minor
        +     platform: linux
        +     run:
        +       args:
        +       - -exc
        +       - |2
        + 
        +         # この時点ではconcorseがgit cloneを実行してるため、git cloneの実行は不要。
        +         # gitのローカルリポジトリのディレクトリに移動
        +         cd repository-with-a-version-bump
        + 
        +         # 現在のバージョンを取得
        +         current_version=$(cat ./version/number)
        + 
        +         # バージョンをバンプするタイプを指定
        +         BUMP_TYPE=${BUMP_TYPE:-"major"}  # デフォルトはメジャーバージョンをバンプ
        + 
        +         # current_version が空文字列の場合
        +         if [ "$current_version" = "" ]; then
        +             # 適切な初期バージョンを設定
        +             if [ "$BUMP_TYPE" = "major" ]; then
        +               new_version="1.0.0"
        +             elif [ "$BUMP_TYPE" = "minor" ]; then
        +               new_version="0.1.0"
        +             elif [ "$BUMP_TYPE" = "patch" ]; then
        +               new_version="0.0.1"
        +             else
        +               echo "Invalid bump_type specified."
        +               exit 1
        +             fi
        +         else
        +           # バージョンをバンプする
        +           IFS_SAVE=$IFS
        +           IFS='.'
        +           set $current_version
        +           IFS=$IFS_SAVE
        +           major="$1"
        +           minor="$2"
        +           patch="$3"
        +           if [ "$BUMP_TYPE" = "major" ]; then
        +             major=$((major + 1))
        +             minor=0
        +             patch=0
        +           elif [ "$BUMP_TYPE" = "minor" ]; then
        +             minor=$((minor + 1))
        +             patch=0
        +           elif [ "$BUMP_TYPE" = "patch" ]; then
        +             patch=$((patch + 1))
        +           fi
        +           new_version="$major.$minor.$patch"
        +         fi
        + 
        +         # 新しいバージョンをファイルに書き込む
        +         echo "$new_version" > ./version/number
        +         cat ./version/number
        + 
        +         # コミットしタグを付加する
        +         git config --global user.email "concourse@local" # メールアドレスは必須（ユーザ名は任意）
        +         git add ./version/number
        +         git commit -m "Bump version to v$new_version"
        +         git tag v$new_version
        +       path: /bin/sh
        +   task: bump-version
        + - params:
        +     repository: repository-with-a-version-bump
        +   put: repository-with-a-version-bump
        
        pipeline name: bump-source-code-minor-version

        pipeline created!
        you can view your pipeline here: http://localhost:8080/teams/main/pipelines/bump-source-code-minor-version

        the pipeline is currently paused. to unpause, either:
        - run the unpause-pipeline command:
            fly -t tutorial unpause-pipeline -p bump-source-code-minor-version
        - click play next to the pipeline in the web ui
        ```

- リソースのチェク

    ```sh
    $ fly -t tutorial check-resource -r bump-source-code-minor-version/version-bump-repository
    ```

    - 結果


- パイプラインの実行

    ```sh
    $ fly -t tutorial unpause-pipeline -p bump-source-code-minor-version
    unpaused 'bump-source-code-minor-version'
    ```

    ```sh
    $ fly -t tutorial trigger-job -j bump-source-code-minor-version/bump-version -w
    ```

    - 結果

</del>

## パイプラインYAMLのファイル名、リソース名、バージョンの保存先フォルダ名を変更する

- 以下のコマンドを実行する

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/pipline
    ```

- 変更内容は以下

    ```sh
    # git log --graph --oneline --decorate=short 
    * 6f9cbab (HEAD -> main, origin/main, origin/HEAD) Update pipline
    * d8c831c Update version dir name and number file name
    * 6ba6578 Update version dir name
    * ea68b76 Update pipline
    * 2db222d Update pipline
    * 1505ad5 Remane version dir
    * 6e1d64e Add number fike
    * 31fd12b Initial commit
    ```
    
    ```sh
    git diff ea68b76 6f9cbab --name-only 
    .version/number
    concourse/pipline/pipeline-bump-source-code-version.yml
    concourse/server/README.md
    ```

    ```sh
    # git diff ea68b76 6f9cbab ./concourse/pipline/pipeline-bump-source-code-version.yml
    ```

    ```diff
    diff --git a/concourse/pipline/pipeline-bump-source-code-version.yml b/concourse/pipline/pipeline-bump-source-code-version.yml
    index 44eafbb..02898ca 100644
    --- a/concourse/pipline/pipeline-bump-source-code-version.yml
    +++ b/concourse/pipline/pipeline-bump-source-code-version.yml
    @@ -35,7 +35,7 @@ jobs:
                    cd repository-with-a-version-bump
    
                    # 現在のバージョンを取得
    -                current_version=$(cat ./version/number)
    +                current_version=$(cat ./.version/number)
                    
                    # バージョンをバンプするタイプを指定
                    BUMP_TYPE=${BUMP_TYPE:-"major"}  # デフォルトはメジャーバージョンをバンプ
    @@ -76,12 +76,12 @@ jobs:
                    fi
            
                    # 新しいバージョンをファイルに書き込む
    -                echo "$new_version" > ./version/number
    -                cat ./version/number
    +                echo "$new_version" > ./.version/number
    +                cat ./.version/number
    
                    # コミットしタグを付加する
                    git config --global user.email "concourse@local" # メールアドレスは必須（ユーザ名は任意）
    -                git add ./version/number
    +                git add ./.version/number
                    git commit -m "Bump version to v$new_version"
                    git tag v$new_version
            params:
    ```

### Concourse WebUIにログインする

- Concourse WebUIにログインする

    ```sh
    $ fly --target tutorial login --concourse-url http://localhost:8080
    ```

    - 操作
    - `http://localhost:8080/login?fly_port=43269` でホストOSのブラウザにアクセスし、表示されたtokenを貼り付ける
    - ユーザID: `test`、パスワード: `test` とする
    - 上記操作をすると、Concourse CI のWeb UIにログインできる

        ```
        logging in to team 'main'

        navigate to the following URL in your browser:

        http://localhost:8080/login?fly_port=43269

        or enter token manually (input hidden): 
        target saved

### Concourse にパイプラインを作成する

- パイプラインを削除する

    ```sh
    $ fly -t tutorial destroy-pipeline -p bump-source-code-minor-version -n
    ```

- パイプラインを作成

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/pipline
    ```

    ```sh
    $ fly -t tutorial set-pipeline -p bump-source-code-minor-version -c pipeline-bump-source-code-version.yml -v bump-type=minor -n
    ```

    - 結果

        ```sh
        resources:
        resource repository-with-a-version-bump has been added:
        + name: repository-with-a-version-bump
        + source:
        +   branch: main
        +   private_key: ((private-key))
        +   uri: git@github.com:moriyamaES/cicd-repo-for-source-code.git
        + type: git
        
        jobs:
        job bump-version has been added:
        + name: bump-version
        + plan:
        + - get: repository-with-a-version-bump
        + - config:
        +     image_resource:
        +       name: ""
        +       source:
        +         repository: getourneau/alpine-bash-git
        +       type: docker-image
        +     inputs:
        +     - name: repository-with-a-version-bump
        +     outputs:
        +     - name: repository-with-a-version-bump
        +     params:
        +       BUMP_TYPE: minor
        +     platform: linux
        +     run:
        +       args:
        +       - -exc
        +       - |2
        + 
        +         # この時点ではconcorseがgit cloneを実行してるため、git cloneの実行は不要。
        +         # gitのローカルリポジトリのディレクトリに移動
        +         cd repository-with-a-version-bump
        + 
        +         # 現在のバージョンを取得
        +         current_version=$(cat ./.version/number)
        + 
        +         # バージョンをバンプするタイプを指定
        +         BUMP_TYPE=${BUMP_TYPE:-"major"}  # デフォルトはメジャーバージョンをバンプ
        + 
        +         # current_version が空文字列の場合
        +         if [ "$current_version" = "" ]; then
        +             # 適切な初期バージョンを設定
        +             if [ "$BUMP_TYPE" = "major" ]; then
        +               new_version="1.0.0"
        +             elif [ "$BUMP_TYPE" = "minor" ]; then
        +               new_version="0.1.0"
        +             elif [ "$BUMP_TYPE" = "patch" ]; then
        +               new_version="0.0.1"
        +             else
        +               echo "Invalid bump_type specified."
        +               exit 1
        +             fi
        +         else
        +           # バージョンをバンプする
        +           IFS_SAVE=$IFS
        +           IFS='.'
        +           set $current_version
        +           IFS=$IFS_SAVE
        +           major="$1"
        +           minor="$2"
        +           patch="$3"
        +           if [ "$BUMP_TYPE" = "major" ]; then
        +             major=$((major + 1))
        +             minor=0
        +             patch=0
        +           elif [ "$BUMP_TYPE" = "minor" ]; then
        +             minor=$((minor + 1))
        +             patch=0
        +           elif [ "$BUMP_TYPE" = "patch" ]; then
        +             patch=$((patch + 1))
        +           fi
        +           new_version="$major.$minor.$patch"
        +         fi
        + 
        +         # 新しいバージョンをファイルに書き込む
        +         echo "$new_version" > ./.version/number
        +         cat ./.version/number
        + 
        +         # コミットしタグを付加する
        +         git config --global user.email "concourse@local" # メールアドレスは必須（ユーザ名は任意）
        +         git add ./.version/number
        +         git commit -m "Bump version to v$new_version"
        +         git tag v$new_version
        +       path: /bin/sh
        +   task: bump-version
        + - params:
        +     repository: repository-with-a-version-bump
        +   put: repository-with-a-version-bump
        
        pipeline name: bump-source-code-minor-version

        pipeline created!
        you can view your pipeline here: http://localhost:8080/teams/main/pipelines/bump-source-code-minor-version

        the pipeline is currently paused. to unpause, either:
        - run the unpause-pipeline command:
            fly -t tutorial unpause-pipeline -p bump-source-code-minor-version
        - click play next to the pipeline in the web ui
        ```


- リソースのチェク

    ```sh
    $ fly -t tutorial check-resource -r bump-source-code-minor-version/version-bump-repository
    ```

    - 結果


- パイプラインの実行

    ```sh
    $ fly -t tutorial unpause-pipeline -p bump-source-code-minor-version
    unpaused 'bump-source-code-minor-version'
    ```

    ```sh
    $ fly -t tutorial trigger-job -j bump-source-code-minor-version/bump-version -w
    ```

    - 結果

        ```sh
        started bump-source-code-minor-version/bump-version #1

        selected worker: 4b95c7837820
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        Cloning into '/tmp/build/get'...
        621dc3b Update version dir name and number file name
        initializing
        initializing check: image
        selected worker: 4b95c7837820
        selected worker: 4b95c7837820
        waiting for docker to come up...
        Pulling getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7...
        docker.io/getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7: Pulling from getourneau/alpine-bash-git
        4fe2ade4980c: Pulling fs layer
        03c196859ec8: Pulling fs layer
        720d2de11875: Pulling fs layer
        720d2de11875: Verifying Checksum
        720d2de11875: Download complete
        03c196859ec8: Verifying Checksum
        03c196859ec8: Download complete
        4fe2ade4980c: Download complete
        4fe2ade4980c: Pull complete
        03c196859ec8: Pull complete
        720d2de11875: Pull complete
        Digest: sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7
        Status: Downloaded newer image for getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7
        docker.io/getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7

        Successfully pulled getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7.

        selected worker: 4b95c7837820
        running /bin/sh -exc 
        # この時点ではconcorseがgit cloneを実行してるため、git cloneの実行は不要。
        # gitのローカルリポジトリのディレクトリに移動
        cd repository-with-a-version-bump

        # 現在のバージョンを取得
        current_version=$(cat ./.version/number)

        # バージョンをバンプするタイプを指定
        BUMP_TYPE=${BUMP_TYPE:-"major"}  # デフォルトはメジャーバージョンをバンプ

        # current_version が空文字列の場合
        if [ "$current_version" = "" ]; then
            # 適切な初期バージョンを設定
            if [ "$BUMP_TYPE" = "major" ]; then
            new_version="1.0.0"
            elif [ "$BUMP_TYPE" = "minor" ]; then
            new_version="0.1.0"
            elif [ "$BUMP_TYPE" = "patch" ]; then
            new_version="0.0.1"
            else
            echo "Invalid bump_type specified."
            exit 1
            fi
        else
        # バージョンをバンプする
        IFS_SAVE=$IFS
        IFS='.'
        set $current_version
        IFS=$IFS_SAVE
        major="$1"
        minor="$2"
        patch="$3"
        if [ "$BUMP_TYPE" = "major" ]; then
            major=$((major + 1))
            minor=0
            patch=0
        elif [ "$BUMP_TYPE" = "minor" ]; then
            minor=$((minor + 1))
            patch=0
        elif [ "$BUMP_TYPE" = "patch" ]; then
            patch=$((patch + 1))
        fi
        new_version="$major.$minor.$patch"
        fi

        # 新しいバージョンをファイルに書き込む
        echo "$new_version" > ./.version/number
        cat ./.version/number

        # コミットしタグを付加する
        git config --global user.email "concourse@local" # メールアドレスは必須（ユーザ名は任意）
        git add ./.version/number
        git commit -m "Bump version to v$new_version"
        git tag v$new_version

        + cd repository-with-a-version-bump
        + cat ./.version/number
        + current_version=
        + BUMP_TYPE=minor
        + '['  '='  ]
        + '[' minor '=' major ]
        + '[' minor '=' minor ]
        + new_version=0.1.0
        + echo 0.1.0
        + cat ./.version/number
        0.1.0
        
        + git add ./.version/number
        + git commit -m 'Bump version to v0.1.0'
        [detached HEAD 5702518] Bump version to v0.1.0
        1 file changed, 1 insertion(+)
        + git tag v0.1.0
        selected worker: 4b95c7837820
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        To github.com:moriyamaES/cicd-repo-for-source-code.git
        621dc3b..5702518  HEAD -> main
        * [new tag]         v0.1.0 -> v0.1.0
        selected worker: 4b95c7837820
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        Cloning into '/tmp/build/get'...
        5702518 Bump version to v0.1.0
        succeeded
        ```

- 成功!!

## パイプライン用YAMLからスプリプとを抜き出す

- 以下のコマンドを実行

    ```sh
    $ cd ./concourse/pipline/
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/pipline (main)]
    $ pwd
    /root/cicd-repo-for-manifesto/concourse/pipline
    ```

- スクリプトの中身は以下

    ```sh
    $ touch bump-version.sh
    ```

    ```sh
    # cat bump-version.sh 
    #!/bin/sh

    # この時点でconcorseがgit cloneを実行してるため、git cloneの実行は不要。
    # gitのローカルリポジトリのディレクトリに移動
    cd repository-with-a-version-bump

    # 現在のバージョンを取得
    current_version=$(cat ./.version/number)

    # バージョンをバンプするタイプを指定
    BUMP_TYPE=${BUMP_TYPE:-"major"}  # デフォルトはメジャーバージョンをバンプ

    # current_version が空文字列の場合
    if [ "$current_version" = "" ]; then
        # 適切な初期バージョンを設定
        if [ "$BUMP_TYPE" = "major" ]; then
        new_version="1.0.0"
        elif [ "$BUMP_TYPE" = "minor" ]; then
        new_version="0.1.0"
        elif [ "$BUMP_TYPE" = "patch" ]; then
        new_version="0.0.1"
        else
        echo "Invalid bump_type specified."
        exit 1
        fi
    else
    # バージョンをバンプする
    IFS_SAVE=$IFS
    IFS='.'
    set $current_version
    IFS=$IFS_SAVE
    major="$1"
    minor="$2"
    patch="$3"
    if [ "$BUMP_TYPE" = "major" ]; then
        major=$((major + 1))
        minor=0
        patch=0
    elif [ "$BUMP_TYPE" = "minor" ]; then
        minor=$((minor + 1))
        patch=0
    elif [ "$BUMP_TYPE" = "patch" ]; then
        patch=$((patch + 1))
    fi
    new_version="$major.$minor.$patch"
    fi

    # 新しいバージョンをファイルに書き込む
    echo "$new_version" > ./.version/number
    cat ./.version/number

    # コミットしタグを付加する
    git config --global user.email "concourse@local" # メールアドレスは必須（ユーザ名は任意）
    git add ./.version/number
    git commit -m "Bump version to v$new_version"
    git tag v$new_versio
    ```

- 実行権限を与える必要が有る模様

    - 公式サイトのスクリプトには実行権限が設定されている。

    ```sh
    $ cd ~/concourse-tutorial/tutorials/basic/task-outputs-to-inputs/
    [root@control-plane ~/concourse-tutorial/tutorials/basic/task-outputs-to-inputs (master)]
    $ ll
    合計 16
    -rwxr-xr-x. 1 root root  173  8月 31 21:27 create_some_files.sh
    -rw-r--r--. 1 root root 1005  8月 31 21:27 pipeline.yml
    -rwxr-xr-x. 1 root root   27  8月 31 21:27 show_files.sh
    -rwxr-xr-x. 1 root root  421  8月 31 21:27 test.sh
    ```

    - 自分の作成したスクリプトには実行実行権限が設定されていない

    ```sh
    [root@control-plane ~/concourse-tutorial/tutorials/basic/task-outputs-to-inputs (master)]
    $ cd ~/cicd-repo-for-manifesto/concourse/pipline/
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/pipline (main *)]
    $ ll
    合計 16
    -rw-r--r--. 1 root root 1616  9月 17 12:12 bump-version.sh
    -rw-r--r--. 1 root root 3658  9月 17 00:07 pipeline-bump-soft-version.yml
    -rw-r--r--. 1 root root 3781  9月 17 10:59 pipeline-bump-source-code-version-include-script.yml
    -rw-r--r--. 1 root root 1927  9月 17 13:23 pipeline-bump-source-code-version.yml
    ```
    
- 実行権限を設定

    ```sh
    $ chmod 755 bump-version.sh 
    [root@control-plane ~/cicd-repo-for-manifesto/concourse/pipline (main *)]
    $ ll
    合計 16
    -rwxr-xr-x. 1 root root 1616  9月 17 12:12 bump-version.sh
    -rw-r--r--. 1 root root 3658  9月 17 00:07 pipeline-bump-soft-version.yml
    -rw-r--r--. 1 root root 3781  9月 17 10:59 pipeline-bump-source-code-version-include-script.yml
    -rw-r--r--. 1 root root 1927  9月 17 13:23 pipeline-bump-source-code-version.yml
    ```

- パイプライン用YAMLの中身は以下

    - 参考

        ```sh
        $ cat pipeline-bump-source-code-version.yml 
        ---
        resources:
        - name: repository-with-a-version-bump
            type: git
            source:
            branch: main
            # sshで認証するため、uriはsshのuriに設定する必要がある(httpsだと正常動作しない）
            uri: git@github.com:moriyamaES/cicd-repo-for-source-code.git
            # GitHubに接続するための秘密鍵はVaultで管理
            private_key: ((private-key))
        - name: repository-of-script
            type: git
            source:
            uri: git@github.com:moriyamaES/cicd-repo-for-manifesto.git
            branch: main
        jobs:
        - name: bump-version
            plan:
            - get: repository-with-a-version-bump
            - task: bump-version
                config:
                platform: linux
                image_resource:
                    type: docker-image
                    # bashとgitが実行できるコンテナをpull
                    source: {repository: getourneau/alpine-bash-git}
                # nputsとoutputsは、同じ名前にしないと正常動作しない模様
                inputs:
                    - name: repository-with-a-version-bump
                outputs:
                    - name: repository-with-a-version-bump
                params:
                    BUMP_TYPE: ((bump-type))
                run:
                    path: repository-of-script/concourse/pipline/bump-version.sh

            # 以下のPUTで、ローカルリポジトリからリポジトリへのpushを実行するため、git pushの実行は不要。
            - put: repository-with-a-version-bump
                params:
                repository: repository-with-a-version-bump
        ```


### Concourse WebUIにログインする

- Concourse WebUIにログインする

    ```sh
    $ fly --target tutorial login --concourse-url http://localhost:8080
    ```

    - 操作
    - `http://localhost:8080/login?fly_port=43269` でホストOSのブラウザにアクセスし、表示されたtokenを貼り付ける
    - ユーザID: `test`、パスワード: `test` とする
    - 上記操作をすると、Concourse CI のWeb UIにログインできる

        ```
        logging in to team 'main'

        navigate to the following URL in your browser:

        http://localhost:8080/login?fly_port=43269

        or enter token manually (input hidden): 
        target saved

### Concourse にパイプラインを作成する

- パイプラインを削除する

    ```sh
    $ fly -t tutorial destroy-pipeline -p bump-source-code-minor-version -n
    ```

- パイプラインを作成

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/pipline
    ```

    ```sh
    $ fly -t tutorial set-pipeline -p bump-source-code-minor-version -c pipeline-bump-source-code-version.yml -v bump-type=minor -n
    ```

    - 結果

        ```sh
        resources:
        resource repository-with-a-version-bump has been added:
        + name: repository-with-a-version-bump
        + source:
        +   branch: main
        +   private_key: ((private-key))
        +   uri: git@github.com:moriyamaES/cicd-repo-for-source-code.git
        + type: git
        
        resource repository-of-script has been added:
        + name: repository-of-script
        + source:
        +   branch: main
        +   uri: https://github.com/moriyamaES/cicd-repo-for-manifesto.git
        + type: git
        
        jobs:
        job bump-version has been added:
        + name: bump-version
        + plan:
        + - get: repository-with-a-version-bump
        + - get: repository-of-script
        + - config:
        +     image_resource:
        +       name: ""
        +       source:
        +         repository: getourneau/alpine-bash-git
        +       type: docker-image
        +     inputs:
        +     - name: repository-with-a-version-bump
        +     - name: repository-of-script
        +     outputs:
        +     - name: repository-with-a-version-bump
        +     params:
        +       BUMP_TYPE: minor
        +     platform: linux
        +     run:
        +       path: repository-of-script/concourse/pipline/bump-version.sh
        +   task: bump-version
        + - params:
        +     repository: repository-with-a-version-bump
        +   put: repository-with-a-version-bump
        
        pipeline name: bump-source-code-minor-version

        pipeline created!
        you can view your pipeline here: http://localhost:8080/teams/main/pipelines/bump-source-code-minor-version

        the pipeline is currently paused. to unpause, either:
        - run the unpause-pipeline command:
            fly -t tutorial unpause-pipeline -p bump-source-code-minor-version
        - click play next to the pipeline in the web ui
        ```

- リソースのチェク

    ```sh
    $ fly -t tutorial check-resource -r bump-source-code-minor-version/repository-with-a-version-bump
    ```

    ```sh
    $ fly -t tutorial check-resource -r bump-source-code-minor-version/repository-of-script
    ```

    - 結果

- パイプラインの実行

    ```sh
    $ fly -t tutorial unpause-pipeline -p bump-source-code-minor-version
    unpaused 'bump-source-code-minor-version'
    ```

    ```sh
    $ fly -t tutorial trigger-job -j bump-source-code-minor-version/bump-version -w
    ```

    - 結果

        ```sh
        started bump-source-code-minor-version/bump-version #1

        selected worker: 4b95c7837820
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        Cloning into '/tmp/build/get'...
        c50ef80 Bump version to v0.3.0
        selected worker: 4b95c7837820
        Cloning into '/tmp/build/get'...
        386f2c8 Update script
        initializing
        initializing check: image
        selected worker: 4b95c7837820
        selected worker: 4b95c7837820
        waiting for docker to come up...
        Pulling getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7...
        docker.io/getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7: Pulling from getourneau/alpine-bash-git
        4fe2ade4980c: Pulling fs layer
        03c196859ec8: Pulling fs layer
        720d2de11875: Pulling fs layer
        4fe2ade4980c: Verifying Checksum
        4fe2ade4980c: Download complete
        03c196859ec8: Verifying Checksum
        03c196859ec8: Download complete
        720d2de11875: Verifying Checksum
        720d2de11875: Download complete
        4fe2ade4980c: Pull complete
        03c196859ec8: Pull complete
        720d2de11875: Pull complete
        Digest: sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7
        Status: Downloaded newer image for getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7
        docker.io/getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7

        Successfully pulled getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7.

        selected worker: 4b95c7837820
        running repository-of-script/concourse/pipline/bump-version.sh
        0.4.0
        [detached HEAD 2277c1e] Bump version to v0.4.0
        1 file changed, 1 insertion(+), 1 deletion(-)
        selected worker: 4b95c7837820
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        To github.com:moriyamaES/cicd-repo-for-source-code.git
        c50ef80..2277c1e  HEAD -> main
        * [new tag]         v0.4.0 -> v0.4.0
        selected worker: 4b95c7837820
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        Cloning into '/tmp/build/get'...
        2277c1e Bump version to v0.4.0
        succeeded
        ```

- 成功！！

## ソースコードリポジトリでのバージョン番号の変更で、マニフェストリポジトリのバージョン番号を変更するパイプラインを作成する

- `pipeline-bump-source-code-version.yml` をコピーする

    ```sh
    $ cp pipeline-bump-source-code-version.yml pipeline-bump-manifesto-version.yml
    ```

- 作成したパイプラインYAMLは以下

    ```sh
    ```

- パイプラインを削除する

    ```sh
    $ fly -t tutorial destroy-pipeline -p bump-manifesto-minor-version -n
    ```

- パイプラインを作成

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/pipline
    ```

    ```sh
    $ fly -t tutorial set-pipeline -p bump-manifesto-minor-version -c pipeline-bump-manifesto-version.yml -v bump-type=minor -n
    ```

    - 結果

        ```sh
        resources:
        resource repository-that-trigger has been added:
        + name: repository-that-trigger
        + source:
        +   branch: main
        +   path: .version
        +   uri: https://github.com/moriyamaES/cicd-repo-for-source-code.git
        + type: git
        
        resource repository-with-a-version-bump has been added:
        + name: repository-with-a-version-bump
        + source:
        +   branch: main
        +   private_key: ((private-key))
        +   uri: git@github.com:moriyamaES/cicd-repo-for-manifesto.git
        + type: git
        
        jobs:
        job bump-version has been added:
        + name: bump-version
        + plan:
        + - get: repository-that-trigger
        +   trigger: true
        + - get: repository-with-a-version-bump
        + - get: repository-of-script
        +   resource: repository-with-a-version-bump
        + - config:
        +     image_resource:
        +       name: ""
        +       source:
        +         repository: getourneau/alpine-bash-git
        +       type: docker-image
        +     inputs:
        +     - name: repository-with-a-version-bump
        +     - name: repository-of-script
        +     outputs:
        +     - name: repository-with-a-version-bump
        +     params:
        +       BUMP_TYPE: minor
        +     platform: linux
        +     run:
        +       path: repository-of-script/concourse/pipline/bump-version.sh
        +   task: bump-version
        + - params:
        +     repository: repository-with-a-version-bump
        +   put: repository-with-a-version-bump
        
        pipeline name: bump-manifesto-minor-version

        pipeline created!
        you can view your pipeline here: http://localhost:8080/teams/main/pipelines/bump-manifesto-minor-version

        the pipeline is currently paused. to unpause, either:
        - run the unpause-pipeline command:
            fly -t tutorial unpause-pipeline -p bump-manifesto-minor-version
        - click play next to the pipeline in the web ui
        ```


- リソースのチェク

    ```sh
    $ fly -t tutorial check-resource -r bump-manifesto-minor-version/repository-that-trigger
    ```

    - 結果

        ```sh
        checking bump-manifesto-minor-version/repository-that-trigger in build 1042
        initializing check: repository-that-trigger
        selected worker: 4b95c7837820
        Cloning into '/tmp/git-resource-repo-cache'...
        succeeded
        ```

    ```sh
    $ fly -t tutorial check-resource -r bump-manifesto-minor-version/repository-with-a-version-bump
    ```

    - 結果

        ```sh
        checking bump-manifesto-minor-version/repository-with-a-version-bump in build 1051
        initializing check: repository-with-a-version-bump
        selected worker: 4b95c7837820
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        Cloning into '/tmp/git-resource-repo-cache'...
        succeeded
        ```

- パイプラインの実行

    ```sh
    $ fly -t tutorial unpause-pipeline -p bump-manifesto-minor-version
    unpaused 'bump-source-code-minor-version'
    ```

    ```sh
    $ fly -t tutorial trigger-job -j bump-manifesto-minor-version/bump-version -w
    ```

    - 結果

        ```sh
        started bump-manifesto-minor-version/bump-version #3

        selected worker: 4b95c7837820
        INFO: found existing resource cache

        selected worker: 4b95c7837820
        INFO: found existing resource cache

        selected worker: 4b95c7837820
        INFO: found existing resource cache

        initializing
        initializing check: image
        selected worker: 4b95c7837820
        selected worker: 4b95c7837820
        INFO: found existing resource cache

        selected worker: 4b95c7837820
        running repository-of-script/concourse/pipline/bump-version.sh
        0.3.0
        [detached HEAD 6533082] Bump version to v0.3.0
        1 file changed, 1 insertion(+), 1 deletion(-)
        selected worker: 4b95c7837820
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        To github.com:moriyamaES/cicd-repo-for-manifesto.git
        4b35253..6533082  HEAD -> main
        * [new tag]         v0.3.0 -> v0.3.0
        selected worker: 4b95c7837820
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        Cloning into '/tmp/build/get'...
        6533082 Bump version to v0.3.0
        succeeded
        ```

- 成功！！


## ソースコードリポジトリでのバージョン番号の変更をトリガにして、マニフェストリポジトリのバージョン番号を変更できることを確認した。

- Concoce CI で確認したのでOK


## 「ソースコードリポジトリの内容の取込み」と「マニフェストリポジトリのバージョン番号を変更のジョブ」を一つにまとめる

- `pipeline-bump-source-code-version.yml`をコピーする

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/pipline/
    ```

    ```sh
    $ cp pipeline-bump-source-code-version.yml pipeline-bump-version.yml
    ```

### Vaultを起動

- 以下を参考に実行

    - https://github.com/moriyamaES/vault-install#approle%E8%AA%8D%E8%A8%BC%E3%83%90%E3%83%83%E3%82%AF%E3%82%A8%E3%83%B3%E3%83%89%E3%81%AE%E4%BD%BF%E7%94%A8


- vaultコマンドに今どこのvaultを設定するのかってのを教えてやる。それは環境変数です

    ```sh
    $ export VAULT_ADDR='http://10.1.1.200:8200';echo $VAULT_ADDR
    http://10.1.1.200:8200
    ```

- vaultを起動する

    ```sh
    $ sudo systemctl start vault.service;sudo systemctl status vault.service
    ```

    - 結果

        ```sh
        ● vault.service - "HashiCorp Vault - A tool for managing secrets"
        Loaded: loaded (/usr/lib/systemd/system/vault.service; disabled; vendor preset: disabled)
        Active: active (running) since 金 2023-09-22 20:27:23 JST; 74ms ago
            Docs: https://www.vaultproject.io/docs/
        Main PID: 22295 (vault)
            Tasks: 7
        Memory: 249.9M
        CGroup: /system.slice/vault.service
                └─22295 /usr/bin/vault server -config=/etc/vault.d/vault.hcl

        9月 22 20:27:23 control-plane.minikube.internal vault[22295]: Listener 1: tcp (addr: "10.1.1.200:820...")
        9月 22 20:27:23 control-plane.minikube.internal vault[22295]: Log Level:
        9月 22 20:27:23 control-plane.minikube.internal vault[22295]: Mlock: supported: true, enabled: false
        9月 22 20:27:23 control-plane.minikube.internal vault[22295]: Recovery Mode: false
        9月 22 20:27:23 control-plane.minikube.internal vault[22295]: Storage: file
        9月 22 20:27:23 control-plane.minikube.internal vault[22295]: Version: Vault v1.14.2, built 2023-08-...2Z
        9月 22 20:27:23 control-plane.minikube.internal vault[22295]: Version Sha: 16a7033a0686eca50ee650880...89
        9月 22 20:27:23 control-plane.minikube.internal vault[22295]: ==> Vault server started! Log data wil...w:
        9月 22 20:27:23 control-plane.minikube.internal vault[22295]: 2023-09-22T20:27:23.794+0900 [INFO]  p...""
        9月 22 20:27:23 control-plane.minikube.internal vault[22295]: 2023-09-22T20:27:23.795+0900 [INFO]  c...re
        Hint: Some lines were ellipsized, use -l to show in full.
        ```

- vault unsealする

    - 前の手順より、Unseal Key と Root Token　は以下

    ```sh
    Unseal Key 1: tYN2ZXR6UOJKiMZzhQvu1nZ+5bymI/B8nSM0zQBlP+cH
    Unseal Key 2: zRm7x5T4yjtLWTwwwWaY5K/YL/dplOd+KQ6VyykVeCFH
    Unseal Key 3: 7xXvhns+T4hp8YT4Pd38EqmURNIU20o92itb8PTNmlt4
    Unseal Key 4: Y7iHvD3EVISub6uSjqt4aVxtnC+0B8OF7m6TXmYL5f9+
    Unseal Key 5: K9/xHj95ermVqZTnQlk8ZHJ4xtu4e6d0x+ylMKB90G4r

    Initial Root Token: hvs.AkzMQJ2dOofPjOjsLK7pzmWz
    ```

- 以下のコマンドを実行（5つのUnseal Keyの内、3つのUnseal Keyを3回に分け入力）

    ```sh
    $ vault operator unseal
    ```

- `role-id`を確認（前回起動時からかわっていない）

    ```sh
    $ vault read auth/approle/role/concourse/role-id
    ```

    - 結果

        ```sh
        Key        Value
        ---        -----
        role_id    2bf6997c-c123-5e25-3e22-ebe3c539ff16
        ```


- `secret_id`を確認（前回起動から変わている）

    ```sh
    $ vault write -f auth/approle/role/concourse/secret-id
    ```

    - 結果

        ```sh
        Key                   Value
        ---                   -----
        secret_id             9edfc1bf-bc60-fb8a-75b5-454ba3a47a95
        secret_id_accessor    6989c5bf-37fb-b51a-600e-998c02636244
        secret_id_num_uses    0
        secret_id_ttl         0s
        ```

### Concouseを起動


- 先程のトークンをconcourseCIに設定します！docker-composeファイルに以下を追記するだけです。
- ここでは`secret_id`のみ変更する。

    ```sh
    cd ~/concourse-install
    ```

- 変更箇所は以下

    ```sh
    git diff HEAD 
    ```
    
    ```diff
    diff --git a/docker-compose.yml b/docker-compose.yml
    index 3ea0954..c108d39 100644
    --- a/docker-compose.yml
    +++ b/docker-compose.yml
    @@ -30,7 +30,7 @@ services:
        CONCOURSE_MAIN_TEAM_LOCAL_USER: test
        CONCOURSE_VAULT_URL: http://10.1.1.200:8200
        CONCOURSE_VAULT_AUTH_BACKEND: "approle"
    -      CONCOURSE_VAULT_AUTH_PARAM: "role_id:2bf6997c-c123-5e25-3e22-ebe3c539ff16,secret_id:18cbe4e2-27da-bb78-18d2-9b0cd47f8f6c"
    +      CONCOURSE_VAULT_AUTH_PARAM: "role_id:2bf6997c-c123-5e25-3e22-ebe3c539ff16,secret_id:9edfc1bf-bc60-fb8a-75b5-454ba3a47a95"
    ```

- 変更後の`docker-compose.yml`は以下

    ```sh
    $ cat docker-compose.yml 
    version: '3'

    services:
    db:
        image: postgres
        environment:
        POSTGRES_DB: concourse
        POSTGRES_USER: concourse_user
        POSTGRES_PASSWORD: concourse_pass
        logging:
        driver: "json-file"
        options:
            max-file: "5"
            max-size: "10m"

    web:
        image: concourse/concourse
        command: web
        links: [db]
        depends_on: [db]
        ports: ["8080:8080"]
        volumes: ["./keys/web:/concourse-keys"]
        environment:
        CONCOURSE_EXTERNAL_URL: http://localhost:8080
        CONCOURSE_POSTGRES_HOST: db
        CONCOURSE_POSTGRES_USER: concourse_user
        CONCOURSE_POSTGRES_PASSWORD: concourse_pass
        CONCOURSE_POSTGRES_DATABASE: concourse
        CONCOURSE_ADD_LOCAL_USER: test:test
        CONCOURSE_MAIN_TEAM_LOCAL_USER: test
        CONCOURSE_VAULT_URL: http://10.1.1.200:8200
        CONCOURSE_VAULT_AUTH_BACKEND: "approle"
        CONCOURSE_VAULT_AUTH_PARAM: "role_id:2bf6997c-c123-5e25-3e22-ebe3c539ff16,secret_id:9edfc1bf-bc60-fb8a-75b5-454ba3a47a95"

        logging:
        driver: "json-file"
        options:
            max-file: "5"
            max-size: "10m"

    worker:
        image: concourse/concourse
        command: worker
        privileged: true
        depends_on: [web]
        volumes: ["./keys/worker:/concourse-keys"]
        links: [web]
        stop_signal: SIGUSR2
        environment:
        CONCOURSE_TSA_HOST: web:2222
        # enable DNS proxy to support Docker's 127.x.x.x DNS server
        CONCOURSE_GARDEN_DNS_PROXY_ENABLE: "true"
        logging:
        driver: "json-file"
        options:
            max-file: "5"
            max-size: "10m"
    
    ```

- concourse を再起動


    ```sh
    $ docker-compose down
    ```

    ```sh
    $ docker-compose up -d
    ```

    - 結果

        ```sh
        [+] Running 4/4
        ✔ Network concourse-install_default     Created                                                      0.1s 
        ✔ Container concourse-install-db-1      Started                                                      0.1s 
        ✔ Container concourse-install-web-1     Started                                                      0.1s 
        ✔ Container concourse-install-worker-1  Started                                                      0.0s 
        ```

- ステータスを確認する

    ```sh
    $ docker ps -a | grep conc
    324a78deb236   concourse/concourse                  "dumb-init /usr/loca…"   About a minute ago   Up About a minute                                                              concourse-install-worker-1
    c0542ede38c3   concourse/concourse                  "dumb-init /usr/loca…"   About a minute ago   Up About a minute                  0.0.0.0:8080->8080/tcp, :::8080->8080/tcp   concourse-install-web-1
    3ba7361d338e   postgres                             "docker-entrypoint.s…"   About a minute ago   Up About a minute                  5432/tcp                                    concourse-install-db-1
    ```

### Concourse WebUIにログインする

- Concourse WebUIにログインする

    ```sh
    $ fly --target tutorial login --concourse-url http://localhost:8080
    ```

    - 操作
    - `http://localhost:8080/login?fly_port=43269` でホストOSのブラウザにアクセスし、表示されたtokenを貼り付ける
    - ユーザID: `test`、パスワード: `test` とする
    - 上記操作をすると、Concourse CI のWeb UIにログインできる

        ```
        logging in to team 'main'

        navigate to the following URL in your browser:

        http://localhost:8080/login?fly_port=43269

        or enter token manually (input hidden): 
        target saved

### Concourse にパイプラインを作成する

- パイプラインを削除する

    ```sh
    $ fly -t tutorial destroy-pipeline -p update-manifesto -n
    ```

- パイプラインを作成

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/pipline
    ```

    ```sh
    $ fly -t tutorial set-pipeline -p update-manifesto -c update-manifesto.yml -v bump-type=minor -n
    ```

    - 結果

        ```sh
        resources:
        resource repository-of-manifesto has been added:
        + name: repository-of-manifesto
        + source:
        +   branch: main
        +   private_key: ((private-key))
        +   uri: git@github.com:moriyamaES/cicd-repo-for-manifesto.git
        + type: git
        
        jobs:
        job bump-version-of-manifesto has been added:
        + name: bump-version-of-manifesto
        + plan:
        + - get: repository-of-manifesto
        + - config:
        +     image_resource:
        +       name: ""
        +       source:
        +         repository: getourneau/alpine-bash-git
        +       type: docker-image
        +     inputs:
        +     - name: repository-of-manifesto
        +     outputs:
        +     - name: repository-of-manifesto
        +     params:
        +       BUMP_TYPE: minor
        +     platform: linux
        +     run:
        +       path: repository-of-manifesto/concourse/pipline/bump-version-of-manifesto.sh
        +   task: bump-version-of-manifesto
        + - params:
        +     repository: repository-of-manifesto
        +   put: repository-of-manifesto
        
        pipeline name: update-manifesto

        pipeline created!
        you can view your pipeline here: http://localhost:8080/teams/main/pipelines/update-manifesto

        the pipeline is currently paused. to unpause, either:
        - run the unpause-pipeline command:
            fly -t tutorial unpause-pipeline -p update-manifesto
        - click play next to the pipeline in the web ui
        ```


- リソースのチェク

    ```sh
    $ fly -t tutorial check-resource -r update-manifesto/repository-of-manifesto
    ```

    - 結果

        ```sh
        $ fly -t tutorial check-resource -r update-manifesto/repository-of-manifesto
        checking update-manifesto/repository-of-manifesto in build 1
        initializing check: repository-of-manifesto
        selected worker: 324a78deb236
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        Cloning into '/tmp/git-resource-repo-cache'...
        succeeded
        ```

- パイプラインの実行

    ```sh
    $ fly -t tutorial unpause-pipeline -p update-manifesto
    unpaused 'bump-source-code-minor-version'
    ```

    ```sh
    $ fly -t tutorial trigger-job -j update-manifesto/bump-version-of-manifesto -w
    ```

    - 結果

        ```sh
        started update-manifesto/bump-version-of-manifesto #1

        selected worker: 324a78deb236
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        Cloning into '/tmp/build/get'...
        c5dd6ba Merge pull request #2 from moriyamaES/add-feature
        initializing
        initializing check: image
        selected worker: 324a78deb236
        selected worker: 324a78deb236
        waiting for docker to come up...
        Pulling getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7...
        docker.io/getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7: Pulling from getourneau/alpine-bash-git
        4fe2ade4980c: Pulling fs layer
        03c196859ec8: Pulling fs layer
        720d2de11875: Pulling fs layer
        4fe2ade4980c: Verifying Checksum
        4fe2ade4980c: Download complete
        4fe2ade4980c: Pull complete
        720d2de11875: Verifying Checksum
        720d2de11875: Download complete
        03c196859ec8: Verifying Checksum
        03c196859ec8: Download complete
        03c196859ec8: Pull complete
        720d2de11875: Pull complete
        Digest: sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7
        Status: Downloaded newer image for getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7
        docker.io/getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7

        Successfully pulled getourneau/alpine-bash-git@sha256:246ebea4839401a027da43e406a0ceaf0f763997a516cf85c344425eb913ffe7.

        selected worker: 324a78deb236
        running repository-of-manifesto/concourse/pipline/bump-version-of-manifesto.sh
        0.6.0
        [detached HEAD 87ad96e] Bump version to v0.6.0
        1 file changed, 1 insertion(+), 1 deletion(-)
        selected worker: 324a78deb236
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        To github.com:moriyamaES/cicd-repo-for-manifesto.git
        c5dd6ba..87ad96e  HEAD -> main
        * [new tag]         v0.6.0 -> v0.6.0
        selected worker: 324a78deb236
        Identity added: /tmp/git-resource-private-key (/tmp/git-resource-private-key)
        Cloning into '/tmp/build/get'...
        87ad96e Bump version to v0.6.0
        succeeded
        ```


## Argo CD との連携

    - 2023-09-24：Argo CD の使い方を調査するため、Argo CDを書籍で学習することとした。このため、ここでの調査は一旦中断

<del>

### Argo CD の復習（Argo CD の起動）

- 参考にしたサイト

    - https://github.com/moriyamaES/k8s-argocd#readme


- minkikube の起動

    ```sh
    $ minikube start --vm-driver=none
    😄  Centos 7.9.2009 (hyperv/amd64) 上の minikube v1.31.2
    ✨  既存のプロファイルを元に、none ドライバーを使用します

    🧯  要求された 2200MiB のメモリー割当は、システムのオーバーヘッド (合計システムメモリー: 2909MiB) に十分な空きを残しません。安定性の問題に直面するかも知れません。
    💡  提案: Start minikube with less memory allocated: 'minikube start --memory=2200mb'

    👍  minikube クラスター中のコントロールプレーンの minikube ノードを起動しています
    🔄  「minikube」のために既存の none bare metal machine を再起動しています...
    ℹ️  OS リリースは CentOS Linux 7 (Core) です
    🐳  Docker 24.0.5 で Kubernetes v1.27.4 を準備しています...
    🔗  bridge CNI (コンテナーネットワークインターフェース) を設定中です...
    🤹  ローカルホスト環境を設定中です...

    ❗  'none' ドライバーは既存 VM の統合が必要なエキスパートに向けて設計されています。
    💡  多くのユーザーはより新しい 'docker' ドライバーを代わりに使用すべきです (root 権限が必要ありません！)
    📘  追加の詳細情報はこちらを参照してください: https://minikube.sigs.k8s.io/docs/reference/drivers/none/

    ❗  kubectl と minikube の構成は /root に保存されます
    ❗  kubectl か minikube コマンドを独自のユーザーとして使用するためには、そのコマンドの再配置が必要な場合があります。たとえば、独自の設定を上書きするためには、以下を実行します

        ▪ sudo mv /root/.kube /root/.minikube $HOME
        ▪ sudo chown -R $USER $HOME/.kube $HOME/.minikube

    💡  これは環境変数 CHANGE_MINIKUBE_NONE_USER=true を設定して自動的に行うこともできます
    🔎  Kubernetes コンポーネントを検証しています...
        ▪ gcr.io/k8s-minikube/storage-provisioner:v5 イメージを使用しています
    🌟  有効なアドオン: default-storageclass, storage-provisioner
    🏄  終了しました！kubectl がデフォルトで「minikube」クラスターと「default」ネームスペースを使用するよう設定されました
    ```

- minikube ｎステータス確認

    ```sh
    $ minikube status 
    minikube
    type: Control Plane
    host: Running
    kubelet: Running
    apiserver: Running
    kubeconfig: Configured
    ```

- NameSpaceの作成

    ```sh
    $ kubectl create ns argocd
    namespace/argocd created
    ```

- NameSpaceの作成の確認

    ```sh
    $ kubectl get ns | grep argo
    argocd            Active   2m9s    
    ```

- ArgoCDのデプロイ

    ```sh
    $ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    ```

    - 結果

        ```sh
        customresourcedefinition.apiextensions.k8s.io/applications.argoproj.io created

        customresourcedefinition.apiextensions.k8s.io/applicationsets.argoproj.io created
        customresourcedefinition.apiextensions.k8s.io/appprojects.argoproj.io created
        serviceaccount/argocd-application-controller created
        serviceaccount/argocd-applicationset-controller created
        serviceaccount/argocd-dex-server created
        serviceaccount/argocd-notifications-controller created
        serviceaccount/argocd-redis created
        serviceaccount/argocd-repo-server created
        serviceaccount/argocd-server created
        role.rbac.authorization.k8s.io/argocd-application-controller created
        role.rbac.authorization.k8s.io/argocd-applicationset-controller created
        role.rbac.authorization.k8s.io/argocd-dex-server created
        role.rbac.authorization.k8s.io/argocd-notifications-controller created
        role.rbac.authorization.k8s.io/argocd-server created
        clusterrole.rbac.authorization.k8s.io/argocd-application-controller created
        clusterrole.rbac.authorization.k8s.io/argocd-server created
        rolebinding.rbac.authorization.k8s.io/argocd-application-controller created
        rolebinding.rbac.authorization.k8s.io/argocd-applicationset-controller created
        rolebinding.rbac.authorization.k8s.io/argocd-dex-server created
        rolebinding.rbac.authorization.k8s.io/argocd-notifications-controller created
        rolebinding.rbac.authorization.k8s.io/argocd-server created
        clusterrolebinding.rbac.authorization.k8s.io/argocd-application-controller created
        clusterrolebinding.rbac.authorization.k8s.io/argocd-server created
        configmap/argocd-cm created
        configmap/argocd-cmd-params-cm created
        configmap/argocd-gpg-keys-cm created
        configmap/argocd-notifications-cm created
        configmap/argocd-rbac-cm created
        configmap/argocd-ssh-known-hosts-cm created
        configmap/argocd-tls-certs-cm created
        secret/argocd-notifications-secret created
        secret/argocd-secret created
        service/argocd-applicationset-controller created
        service/argocd-dex-server created
        service/argocd-metrics created
        service/argocd-notifications-controller-metrics created
        service/argocd-redis created
        service/argocd-repo-server created
        service/argocd-server created
        service/argocd-server-metrics created
        deployment.apps/argocd-applicationset-controller created
        deployment.apps/argocd-dex-server created
        deployment.apps/argocd-notifications-controller created
        deployment.apps/argocd-redis created
        deployment.apps/argocd-repo-server created
        deployment.apps/argocd-server created
        statefulset.apps/argocd-application-controller created
        networkpolicy.networking.k8s.io/argocd-application-controller-network-policy created
        networkpolicy.networking.k8s.io/argocd-applicationset-controller-network-policy created
        networkpolicy.networking.k8s.io/argocd-dex-server-network-policy created
        networkpolicy.networking.k8s.io/argocd-notifications-controller-network-policy created
        networkpolicy.networking.k8s.io/argocd-redis-network-policy created
        networkpolicy.networking.k8s.io/argocd-repo-server-network-policy created
        networkpolicy.networking.k8s.io/argocd-server-network-policy created 
        ```

- ArgoCDのデプロイの確認

    ```sh
    $ kubectl get svc -n argocd
    ```

    - 結果

        ```sh
        kubectl get svc -n argocd
        NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
        argocd-applicationset-controller          ClusterIP   10.106.238.91    <none>        7000/TCP,8080/TCP            4m34s
        argocd-dex-server                         ClusterIP   10.102.215.235   <none>        5556/TCP,5557/TCP,5558/TCP   4m34s
        argocd-metrics                            ClusterIP   10.104.232.249   <none>        8082/TCP                     4m34s
        argocd-notifications-controller-metrics   ClusterIP   10.110.202.232   <none>        9001/TCP                     4m34s
        argocd-redis                              ClusterIP   10.100.59.25     <none>        6379/TCP                     4m34s
        argocd-repo-server                        ClusterIP   10.100.222.80    <none>        8081/TCP,8084/TCP            4m34s
        argocd-server                             ClusterIP   10.96.60.13      <none>        80/TCP,443/TCP               4m34s
        argocd-server-metrics                     ClusterIP   10.108.251.73    <none>        8083/TCP                     4m34s
        ```

- Create Service with NodePort type (port: 30080)

    ```sh
    $ cd ~/kubernetes-basics/
    ```

    ```sh
    # ll
    合計 12
    drwxr-xr-x. 2 root root  168  8月 12 08:40 03-environment-setup
    drwxr-xr-x. 2 root root   64  8月 12 08:40 04-kubectl
    drwxr-xr-x. 9 root root  154  8月 12 08:40 05-kubernetes-resources
    drwxr-xr-x. 2 root root 4096  8月 12 10:50 06-run-simple-application-in-kubernetes
    drwxr-xr-x. 2 root root 4096  8月 12 10:50 07-debug-kubernetes
    drwxr-xr-x. 2 root root   23  8月 12 10:50 08-setup-eks-cluster
    drwxr-xr-x. 2 root root  249  8月 12 08:40 09-assignment
    drwxr-xr-x. 5 root root  191  8月 12 10:50 09-cicd
    -rw-r--r--. 1 root root  750  8月 12 08:40 README.md
    drwxr-xr-x. 2 root root   35  8月 12 08:40 argocd-test 
    ```

    ```sh
    $ kubectl apply -f 09-cicd/argocd-install/argocd-server-node-port.yaml -n argocd
    service/argocd-server-node-port created
    ```

- Port forward the service (port: 30080)

    ```sh
    kubectl -n argocd port-forward service/argocd-server 30080:80
    ```

- Login
- Usernameは「admin」ですが、Passwordについては以下のコマンドで取得します。

    Open http://localhost:30080, click on `Advanced` and `Proceed to localhost (unsafe)` (this is ok because we're connecting to the argocd running in our local computer)

    - username: `admin`
    - password: `kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 --decode`

- 以降

    - 以下のサイトの「検証環境の構築」以降を実施

    https://selfnote.work/20220703/programming/kubernetes-microservices-volumes-2/#%E6%A4%9C%E8%A8%BC%E7%92%B0%E5%A2%83%E3%81%AE%E6%A7%8B%E7%AF%89


- `application.yaml`の作成

<deL>

- `.version`フォルダの更新をトリガとしている


    ```sh
    cd ~/cicd-repo-for-manifesto/argo-cd
    ```

    ```sh
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
    name: myapp-argo-application
    namespace: argocd
    spec:
    project: default
    source:
        repoURL: https://github.com/moriyamaES/cicd-repo-for-manifesto.git
        targetRevision: HEAD
        path: .version
    destination:
        server: https://kubernetes.default.svc
        namespace: myapp
    
    syncPolicy:
        syncOptions:
        - CreateNamespace=true
        automated:
        selfHeal: true
    ```

</del>


- 以下のコマンドを実行

    ```sh
    $ cd ~/cicd-repo-for-manifesto/argo-cd/
    ```

    ```sh
    $ kubectl apply -f application.yaml
    ```

</del>