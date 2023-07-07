- [AmazonのElastic Container Service(ECS)でSplunkを実行する](https://www.splunk.com/ja_jp/blog/tips-and-tricks/running-splunk-in-amazon-s-elastic-container-service.html)
- [ECSのログをSplunkに送る](https://qiita.com/kikeyama/items/e92befb361565ff61b03)

- home_ip
  - 接続元の IP
- ecs.tf > aws_ecs_task_definition.splunk-service-def の SPLUNK_PASSWORD
  - 適宜書き換えたり、Secret Manager で管理するなど対応必要
