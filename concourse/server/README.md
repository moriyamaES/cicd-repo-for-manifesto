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


## Concourse CI の停止

- これまでの設定で起動していた Concourse CI を停止する

    ```sh
    $ docker-compose down
    [+] Running 4/4
    ✔ Container concourse-install-worker-1  Removed                                                                                                                                                         10.3s 
    ✔ Container concourse-install-web-1     Removed                                                                                                                                                         10.4s 
    ✔ Container concourse-install-db-1      Removed                                                                                                                                                          0.5s 
    ✔ Network concourse-install_default     Removed 
    ```

## Concourse CI を起動する

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

## Concourse WebUIにログインする

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

## Concurse CI からGitHubに書込むパイプラインの動作確認を行う

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
    - 隠しフォルダ`.version/`は更新できない？

    - 隠しフォルダ`.version/`を通常のフォルダに戻す


### パイプラインYAMLのファイル名、リソース名、バージョンの保存先フォルダ名を変更する

- 以下のコマンドを実行する

    ```sh
    $ cd ~/cicd-repo-for-manifesto/concourse/pipline
    ```