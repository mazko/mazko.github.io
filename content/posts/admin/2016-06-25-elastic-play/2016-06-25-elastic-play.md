title: ElasticSearch - практическое введение
category: Admin
tags: Elastic, REST, Docker

[ElasticSearch](https://www.elastic.co/products/elasticsearch){:rel="nofollow"} - поисковый движок с JSON REST API, использующий под капотом [Lucene]({filename}../../java/lucene/2012-10-15-lucene-real-world/2012-10-15-lucene-real-world.md). Предлагаю смастерить с помощью Elastic поиск для парочки [фильмов]({filename}../../java/lucene/2016-05-15-lucene-facet/2016-05-15-lucene-facet.md). На первом этапе рассмотрим установку и настройка Elastic в Docker контейнере, впрочем это опционально - вы можете установить Elastic любым другим [способом](https://www.elastic.co/guide/en/elasticsearch/reference/current/_installation.html){:rel="nofollow"}. Затем копнём поглубже в [процесс индексации]({filename}../../java/lucene/2012-10-17-lucene-real-world---indexing/2012-10-17-lucene-real-world---indexing.md), [поисковые запросы]({filename}../../java/lucene/2012-10-29-lucene-real-world---syntax/2012-10-29-lucene-real-world---syntax.md),
[подсветку]({filename}../../java/lucene/2012-10-28-lucene-real-world---highlighting/2012-10-28-lucene-real-world---highlighting.md) вхождений в результатах выдачи и [агрегацию данных]({filename}../../java/lucene/2016-05-15-lucene-facet/2016-05-15-lucene-facet.md) в Elastic и всё это только лишь с помощью REST API без необходимости наличия каких-либо глубоких познаний как в самом Lucene так и в программировании в целом !

##TL;DR

Предполагается что ElasticSearch уже установлен и настроен:

    :::bash
    ~$ curl -XGET localhost:9200
    # response
    {
      "name" : "J2",
      "cluster_name" : "docker-cluster",
      "version" : {
        "number" : "2.3.3",
        "build_hash" : "218bdf10790eef486ff2c41a3df5cfa32dadcfde",
        "build_timestamp" : "2016-05-17T15:40:04Z",
        "build_snapshot" : false,
        "lucene_version" : "5.5.0"
      },
      "tagline" : "You Know, for Search"
    }

Достаточно просто проиндексировать содержимое дампа [Top.json.xz]({attach}Top.json.xz):

    :::bash
    # field mapping for suggest
    # curl -XDELETE 'localhost:9200/kinopoisk?pretty'
    ~$ curl -XPUT 'localhost:9200/kinopoisk?pretty' -d '{
      "mappings": {
        "film" : {
          "properties" : {
            "suggest" : { 
              "type" : "completion",
              "analyzer": "standard"
            },
            "category": {
              "type": "string",
              "fields": {
                  "raw": {
                      "type": "string",
                      "index": "not_analyzed"
                  }
              }
            },
            "directed": {
              "type": "string",
              "fields": {
                  "raw": {
                      "type": "string",
                      "index": "not_analyzed"
                  }
              }
            }
          }
        }
      }
    }'

    # index
    ~$ xzcat Top.json.xz | curl -XPOST localhost:9200/_bulk --data-binary @-

Поля *category*, *directed* в терминологии Elastic являются [multi-field](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/_multi_fields.html){:rel="nofollow"}, в нашем случае они дополнительно хранят оригинальные значения что позволит агрегировать и фильтровать выдачу по строгому совпадению - например режиссёр "Игорь Масленников" вместо "Игорь" и "Масленников" по отдельности. После индексации собственно можно осуществлять поиск с подсветкой, агрегацией и фильтрацией, к осознанию которого было бы здорово подойти по окончании данного материала:

    :::bash
    ~$ curl -XGET 'localhost:9200/kinopoisk/film/_search?pretty' -d ' {
      "fields" : ["id"],
      "query" : {
        "bool": {
          "must": [
            {
              "query_string" : {
                "query":    "шерлок", 
                "fields": [ "name", "description" ],
                "default_operator": "and"
              }
            }
          ],
          "filter": [
            {
              "match": {
                "directed.raw": "Игорь Масленников"
              }
            },
            {
              "bool": {
                "must": [
                  {
                    "match": {
                      "category.raw": "детектив"
                    }
                  },
                  {
                    "match": {
                      "category.raw": "криминал"
                    }
                  }
                ]
              }
            },
            {
              "range" : {
                "date" : {
                  "gte" : "1980",
                  "lt" : "1980||+1y",
                  "format": "yyyy-MM||yyyy"
                }
              }
            }
          ]
        }
      },
      "highlight" : {
        "pre_tags" : ["[mazko.github.io]"],
        "post_tags" : ["[/mazko.github.io]"],
        "fields" : {
          "name" : {"fragment_size" : 22, "number_of_fragments" : 1},
          "description" : {"fragment_size" : 22, "number_of_fragments" : 1}
        }
      },
      "aggs": {
        "years": {
          "date_histogram": {
            "field": "date",
            "interval": "year",
            "min_doc_count": 1,
            "order" : { "_count" : "desc" }
          },
          "aggs": {
            "months": {
              "date_histogram": {
                "field": "date",
                "interval": "month",
                "min_doc_count": 1,
                "order" : { "_count" : "desc" }
              }
            }
          }
        },
        "category" : {
          "terms" : { "field" : "category.raw", "size": 0 }
        },
        "directed" : {
          "terms" : { "field" : "directed.raw", "size": 0 }
        }
      }
    }'
    # response
    {
      "took" : 149,
      "timed_out" : false,
      "_shards" : {
        "total" : 5,
        "successful" : 5,
        "failed" : 0
      },
      "hits" : {
        "total" : 5,
        "max_score" : 2.638543,
        "hits" : [ {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "77269",
          "_score" : 2.638543,
          "fields" : {
            "id" : [ 77269 ]
          },
          "highlight" : {
            "name" : [ "[mazko.github.io]Шерлок[/mazko.github.io] Холмс и доктор" ],
            "description" : [ " [mazko.github.io]Шерлок[/mazko.github.io] Холмс. Это" ]
          }
        }, {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "77265",
          "_score" : 2.477974,
          "fields" : {
            "id" : [ 77265 ]
          },
          "highlight" : {
            "name" : [ "[mazko.github.io]Шерлок[/mazko.github.io] Холмс и доктор" ],
            "description" : [ ". Во второй — [mazko.github.io]Шерлок[/mazko.github.io]" ]
          }
        }, {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "368936",
          "_score" : 2.466133,
          "fields" : {
            "id" : [ 368936 ]
          },
          "highlight" : {
            "name" : [ "[mazko.github.io]Шерлок[/mazko.github.io] Холмс и доктор" ],
            "description" : [ " угрозой. [mazko.github.io]Шерлок[/mazko.github.io] Холмс" ]
          }
        }, {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "354799",
          "_score" : 2.1987858,
          "fields" : {
            "id" : [ 354799 ]
          },
          "highlight" : {
            "name" : [ "[mazko.github.io]Шерлок[/mazko.github.io] Холмс и доктор" ],
            "description" : [ "[mazko.github.io]Шерлок[/mazko.github.io] Холмс вступил" ]
          }
        }, {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "368937",
          "_score" : 1.2330666,
          "fields" : {
            "id" : [ 368937 ]
          },
          "highlight" : {
            "description" : [ " водопада. [mazko.github.io]Шерлок[/mazko.github.io] Холмс" ]
          }
        } ]
      },
      "aggregations" : {
        "directed" : {
          "doc_count_error_upper_bound" : 0,
          "sum_other_doc_count" : 0,
          "buckets" : [ {
            "key" : "Игорь Масленников",
            "doc_count" : 5
          } ]
        },
        "category" : {
          "doc_count_error_upper_bound" : 0,
          "sum_other_doc_count" : 0,
          "buckets" : [ {
            "key" : "детектив",
            "doc_count" : 5
          }, {
            "key" : "криминал",
            "doc_count" : 5
          } ]
        },
        "years" : {
          "buckets" : [ {
            "key_as_string" : "1980-01-01T00:00:00.000Z",
            "key" : 315532800000,
            "doc_count" : 5,
            "months" : {
              "buckets" : [ {
                "key_as_string" : "1980-01-01T00:00:00.000Z",
                "key" : 315532800000,
                "doc_count" : 3
              }, {
                "key_as_string" : "1980-03-01T00:00:00.000Z",
                "key" : 320716800000,
                "doc_count" : 2
              } ]
            }
          } ]
        }
      }
    }

В запросе мы искали строку *шерлок* по полям *name* и *description*, исключили все фильмы кроме режиссёра "Игорь Масленников", жанры дожны быть только и *детектив* и *криминал*, только 1980 год. Простая агрегация по полям *category*, *directed*. Вложенная агрегация по дате - годы и в них месяцы. Но обо всём по порядку :)

##УСТАНОВКА И НАСТРОЙКА ELASTICSEARCH

Предполагается что в системе уже установлен [Docker](https://docs.docker.com/engine/installation/){:rel="nofollow"}:

    :::bash
    ~$ docker -v
    Docker version 1.11.2, build b9f10c9

    ~$ docker pull ubuntu && docker run -it ubuntu

    root@d1b1c0c6bddc:/# cat /etc/lsb-release
    DISTRIB_ID=Ubuntu
    DISTRIB_RELEASE=16.04
    DISTRIB_CODENAME=xenial
    DISTRIB_DESCRIPTION="Ubuntu 16.04 LTS"

    root@d1b1c0c6bddc:/# apt update && apt -y upgrade && \
      apt -y install software-properties-common command-not-found \
      man-db openjdk-8-jdk wget curl net-tools

    root@d1b1c0c6bddc:/# wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -

    root@d1b1c0c6bddc:/# echo "deb https://packages.elastic.co/elasticsearch/2.x/debian stable main" |\
      tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list

    root@d1b1c0c6bddc:/# apt -y install apt-transport-https && apt update && apt install -y elasticsearch

    root@d1b1c0c6bddc:/# cd /usr/share/elasticsearch/
    root@d1b1c0c6bddc:/# mkdir config/ && chown elasticsearch:elasticsearch config/
    root@d1b1c0c6bddc:/# mkdir logs/ && chown elasticsearch:elasticsearch logs/
    root@d1b1c0c6bddc:/# mkdir data/ && chown elasticsearch:elasticsearch data/

    root@d1b1c0c6bddc:/# cat <<EOT > /usr/share/elasticsearch/config/logging.yml
    rootLogger: TRACE,console
    appender:
      console:
        type: console
        layout:
          type: consolePattern
          conversionPattern: "[%d{ISO8601}][%-5p][%-25c] %m%n"
    EOT

    root@d1b1c0c6bddc:/# cat <<EOT > /usr/share/elasticsearch/config/elasticsearch.yml
    cluster.name: "docker-cluster"
    network.host: 0.0.0.0
    http.max_content_length: 333mb
    http.cors:
      enabled: true 
      allow-origin: /https?:\/\/localhost(:[0-9]+)?/
      allow-methods: OPTIONS, HEAD, GET, POST, PUT, DELETE
      allow-headers: X-Requested-With,X-Auth-Token,Content-Type, Content-Length
    EOT

    root@d1b1c0c6bddc:/# exit

В [настройках](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-http.html#_settings_2){:rel="nofollow"} мы добавили поддержку ```http.cors``` чтобы с elastic можно было работать напрямую из браузера. На этом установка и настройка завершена - осталось зафиксировать изменения и запустить образ:

    :::bash
    ~$ docker commit d1b1c0c6bddc elastic
    ~$ docker rm d1b1c0c6bddc

    ~$ docker run --rm -it -u elasticsearch -p 9200:9200 elastic \
      /usr/share/elasticsearch/bin/elasticsearch

Проверка ```http.cors```:

    :::bash
    ~$ curl -I -H 'Origin: http://localhost:8080' 'http://localhost:9200/'
    # response
    HTTP/1.1 200 OK
    Access-Control-Allow-Origin: http://localhost:8080
    Content-Type: text/plain; charset=UTF-8
    Content-Length: 0

    ~$ curl -I -H 'Origin: http://some.hacker.com' 'http://localhost:9200/'
    # response
    HTTP/1.1 403 Forbidden

В настойках ```http.cors``` нет упоминаний о some.hacker.com поэтому справедливо 403. Наконец если мы хотим чтобы данные работы образа elastic сохранялись после его перезапуска:

    :::bash
    ~$ docker volume create --name elastic-data

    # user: elasticsearch, port forward 9200, image: elastic, volume: elastic-data
    ~$ docker run --rm -it -u elasticsearch -p 9200:9200 \
      -v elastic-data:/usr/share/elasticsearch/data elastic \
      /usr/share/elasticsearch/bin/elasticsearch

С Docker всё.

##REST API

Индексация:

    :::bash
    ~$ curl -XPOST 'localhost:9200/kinopoisk/film?pretty' -d {'
      "id": 409640,
      "name": "Касл (сериал 2009 – ...)",
      "description": "Знакомьтесь, Ричард Касл — успешный писатель детективного жанра...",
      "date": "2009-03-08T22:00:00.000Z",
      "rate": 8.042,
      "starring": [
        "Нэйтан Филлион",
        "Стана Катик",
        "Сьюзэн Салливан",
        "Джон Уэртас",
        "Шеймус Девер",
        "Молли К. Куинн",
        "Тамала Джонс",
        "Пенни Джонсон",
        "Рубен Сантьяго-Хадсон",
        "Майя Стоян"
      ],
      "category": [
        "драма",
        "мелодрама",
        "комедия",
        "криминал",
        "детектив"
      ],
      "directed": [
        "Роб Боумен",
        "Джон Терлески",
        "Билл Роу"
      ]
    }'
    # response
    {
      "_index" : "kinopoisk",
      "_type" : "film",
      "_id" : "AVWHlznJTgOouHAvlXph",
      "_version" : 1,
      "_shards" : {
        "total" : 2,
        "successful" : 1,
        "failed" : 0
      },
      "created" : true
    }

    ~$ curl -XPOST 'localhost:9200/kinopoisk/film?pretty' -d {'
      "id": 153013,
      "name": "Звездный крейсер Галактика (сериал 2004 – 2009)",
      "description": "Чудом уцелев после нападения Сайлонов...",
      "date": "2004-10-17T21:00:00.000Z",
      "rate": 7.943,
      "starring": [
        "Эдвард Джеймс Олмос",
        "Мэри МакДоннелл",
        "Джейми Бамбер",
        "Джеймс Кэллис",
        "Триша Хелфер",
        "Грейс Пак",
        "Кэти Сакхофф",
        "Майкл Хоган",
        "Аарон Дуглас",
        "Тамо Пеникетт"
      ],
      "category": [
        "фантастика",
        "боевик",
        "драма",
        "приключения"
      ],
      "directed": [
        "Майкл Раймер",
        "Майкл Нанкин",
        "Род Харди"
      ]
    }'
    # response
    {
      "_index" : "kinopoisk",
      "_type" : "film",
      "_id" : "AVWHnN7ATgOouHAvlXpl",
      "_version" : 1,
      "_shards" : {
        "total" : 2,
        "successful" : 1,
        "failed" : 0
      },
      "created" : true
    }

    ~$ curl -XGET 'localhost:9200/kinopoisk/_mapping?pretty'
    # response
    {
      "kinopoisk" : {
        "mappings" : {
          "film" : {
            "properties" : {
              "category" : {
                "type" : "string"
              },
              "date" : {
                "type" : "date",
                "format" : "strict_date_optional_time||epoch_millis"
              },
              "description" : {
                "type" : "string"
              },
              "directed" : {
                "type" : "string"
              },
              "id" : {
                "type" : "long"
              },
              "name" : {
                "type" : "string"
              },
              "rate" : {
                "type" : "double"
              },
              "starring" : {
                "type" : "string"
              }
            }
          }
        }
      }
    }

ElasticSearch автоматически и даже правильно распознал типы данных для всех полей в индексе ! Простой [постраничный](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-from-size.html){:rel="nofollow"} поиск по двум полям *name* и *description*, в результатах поиска выводить только значение поля *id*:

    :::bash
    ~$ curl -XGET 'localhost:9200/kinopoisk/film/_search?pretty' -d {'
        "fields" : ["id", "rate"],
        "query" : {
          "query_string" : {
            "query":    "Касл", 
            "fields": [ "name", "description" ],
            "default_operator": "and"
          }
        }
    }'
    # response
    {
      "took" : 8,
      "timed_out" : false,
      "_shards" : {
        "total" : 5,
        "successful" : 5,
        "failed" : 0
      },
      "hits" : {
        "total" : 1,
        "max_score" : 0.15342641,
        "hits" : [ {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "AVWHmwbSTgOouHAvlXpi",
          "_score" : 0.15342641,
          "fields" : {
            "rate" : [ 8.042 ],
            "id" : [ 409640 ]
          }
        } ]
      }
    }

Поиск с подсветкой:

    :::bash
    ~$ curl -XGET 'localhost:9200/kinopoisk/film/_search?pretty' -d {'
        "fields" : ["id", "rate"],
        "query" : {
          "query_string" : {
            "query":    "сайлон*", 
            "fields": [ "name", "description" ],
            "default_operator": "and"
          }
        },
        "highlight" : {
          "pre_tags" : ["[mazko.github.io]"],
          "post_tags" : ["[/mazko.github.io]"],
          "fields" : {
            "name" : {"fragment_size" : 22, "number_of_fragments" : 1},
            "description" : {"fragment_size" : 22, "number_of_fragments" : 1}
          }
        }
    }'
    # response
    {
      "took" : 218,
      "timed_out" : false,
      "_shards" : {
        "total" : 5,
        "successful" : 5,
        "failed" : 0
      },
      "hits" : {
        "total" : 1,
        "max_score" : 1.0,
        "hits" : [ {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "AVWHnN7ATgOouHAvlXpl",
          "_score" : 1.0,
          "fields" : {
            "rate" : [ 7.943 ],
            "id" : [ 153013 ]
          },
          "highlight" : {
            "description" : [ " нападения [mazko.github.io]Сайлонов[/mazko.github.io]..." ]
          }
        } ]
      }
    }

Самое время для реальных [данных]({filename}../../java/lucene/2016-05-20-lucene-suggest/2016-05-20-lucene-suggest.md):

    :::bash
    ~: curl -XDELETE 'localhost:9200/kinopoisk?pretty'

    ~: time python3 -c \
      'import sys, json; [print(json.dumps(i, ensure_ascii=False)) for i in json.load(sys.stdin)]' \
      < Top.json | xargs -d '\n' -n1 curl -XPOST 'localhost:9200/kinopoisk/film/' -d
    
    # time
    real  18m52.728s
    user  1m36.896s
    sys   0m36.216s

Процесс индексации можно значительно ускорить используя [Bulk API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html){:rel="nofollow"}:

    :::bash
    ~: curl -XDELETE 'localhost:9200/kinopoisk?pretty'

    ~: time python3 -c \
      'import sys, json; [print(json.dumps({ "index" : { "_index" : "kinopoisk", "_type" : "film" } }),
      "\n", json.dumps(i, ensure_ascii=False)) for i in json.load(sys.stdin)]' \
       < Top.json | curl -XPOST localhost:9200/_bulk --data-binary @-
    
    # time
    real  0m14.450s
    user  0m1.044s
    sys   0m0.196s

Немного полезной статистики об индексе:

    :::bash
    ~: curl -XGET 'localhost:9200/kinopoisk/_count?pretty'
    # response
    {
      "count" : 14999,
      "_shards" : {
        "total" : 5,
        "successful" : 5,
        "failed" : 0
      }
    }

    ~: curl -XGET 'localhost:9200/_cat/indices'
    # response
    yellow open kinopoisk 5 1 14999 0 39.1mb 39.1mb

[Suggest](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-suggesters-completion.html){:rel="nofollow"} в ElasticSearch довольно странный либо плохо описанный:

    :::bash
    ~: curl -XDELETE 'localhost:9200/kinopoisk?pretty'

    ~: curl -XPUT 'localhost:9200/kinopoisk?pretty' -d '{
      "settings": {
        "analysis": {
          "filter": {
            "shingle_filter": {
              "type": "shingle",
              "max_shingle_size": "5",
              "min_shingle_size": "2",
              "output_unigrams":"true"
            }
          },
          "analyzer": {
            "pre_suggest_analyzer": {
              "type": "custom",
              "tokenizer": "standard",
              "filter": [
                "lowercase",
                "shingle_filter"
              ]
            }
          }
        }
      }
    }'

    ~: curl -XGET 'localhost:9200/kinopoisk/_analyze?pretty' -d '{
      "analyzer": "pre_suggest_analyzer",
      "text": ["раз два", "раз"]
    }'
    #response
    {
      "tokens" : [ {
        "token" : "раз",
        "start_offset" : 0,
        "end_offset" : 3,
        "type" : "<ALPHANUM>",
        "position" : 0
      }, {
        "token" : "раз два",
        "start_offset" : 0,
        "end_offset" : 7,
        "type" : "shingle",
        "position" : 0
      }, {
        "token" : "два",
        "start_offset" : 4,
        "end_offset" : 7,
        "type" : "<ALPHANUM>",
        "position" : 1
      }, {
        "token" : "раз",
        "start_offset" : 8,
        "end_offset" : 11,
        "type" : "<ALPHANUM>",
        "position" : 102
      } ]
    }

Исходя из документации несовсем понятно как в процессе индексации сделать такую штуку автоматической без избыточных HTTP запросов к *localhost:9200/kinopoisk/_analyze*:

    :::bash
    ~: python3 -c '
    import sys, json
    from urllib.request import urlopen

    def get_shingles(*args):
      data = {
        "analyzer": "pre_suggest_analyzer",
        "text": args
      }
      data = json.dumps(data).encode("utf8")
      with urlopen("http://localhost:9200/kinopoisk/_analyze", data=data) as r:
        data = json.loads(r.read().decode(r.info().get_param("charset") or "utf-8"))
        tokens = map(lambda v: v["token"], data["tokens"])
        tokens = filter(lambda v: len(v) > 1, tokens)
        return list(set(tokens))

    data = json.load(sys.stdin)
    for film in data:
      film["rate"] = float(film["rate"])
      film["suggest"] = {
        "input": get_shingles(film["name"], film["description"])
      }
      print(
        json.dumps({ 
          "index" : { "_index" : "kinopoisk", "_type" : "film", "_id" : film["id"]} 
       }), 
       "\n", 
       json.dumps(film, ensure_ascii=False))
    ' < Top.json | xz --extreme -9 > Top.json.xz

Индекс уже с Suggest:

    :::bash
    ~: curl -XDELETE 'localhost:9200/kinopoisk?pretty'

    ~: curl -XPUT 'localhost:9200/kinopoisk?pretty' -d '{
      "mappings": {
        "film" : {
          "properties" : {
            "suggest" : { 
              "type" : "completion",
              "analyzer": "standard"
              }
            }
          }
        }
      }
    }'

    ~: xzcat Top.json.xz | curl -XPOST localhost:9200/_bulk --data-binary @-

    ~: curl -XGET 'localhost:9200/kinopoisk/_suggest?pretty' -d '{
      "film-suggest" : {
        "text" : "шерлок ",
        "completion" : {
            "field" : "suggest",
            "size": 5
        }
      }
    }'
    #response
    {
      "_shards" : {
        "total" : 5,
        "successful" : 5,
        "failed" : 0
      },
      "film-suggest" : [ {
        "text" : "шерлок ",
        "offset" : 0,
        "length" : 7,
        "options" : [ {
          "text" : "шерлок холмс",
          "score" : 2.0
        }, {
          "text" : "шерлок младший",
          "score" : 1.0
        }, {
          "text" : "шерлок младший который",
          "score" : 1.0
        }, {
          "text" : "шерлок младший который расследуя",
          "score" : 1.0
        }, {
          "text" : "шерлок младший который расследуя преступление",
          "score" : 1.0
        } ]
      } ]
    }

Поиск с [агрегацией](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-terms-aggregation.html){:rel="nofollow"}:

    :::bash
    ~$ curl -XDELETE 'localhost:9200/kinopoisk?pretty'

    ~$ curl -XPUT 'localhost:9200/kinopoisk?pretty' -d '{
      "mappings": {
        "film" : {
          "properties" : {
            "category": {
              "type": "string",
              "fields": {
                  "raw": {
                      "type": "string",
                      "index": "not_analyzed"
                  }
              }
            },
            "directed": {
              "type": "string",
              "fields": {
                  "raw": {
                      "type": "string",
                      "index": "not_analyzed"
                  }
              }
            }
          }
        }
      }
    }'

    ~$ xzcat Top.json.xz | curl -XPOST localhost:9200/_bulk --data-binary @-

    ~$ curl -XGET 'localhost:9200/kinopoisk/film/_search?pretty' -d {'
      "fields" : ["id"],
      "query" : {
        "query_string" : {
          "query":    "шерлок", 
          "fields": [ "name", "description" ],
          "default_operator": "and"
        }
      },
      "aggs": {
        "years": {
          "date_histogram": {
            "field": "date",
            "interval": "year",
            "min_doc_count": 1,
            "order" : { "_count" : "desc" }
          },
          "aggs": {
            "months": {
              "date_histogram": {
                "field": "date",
                "interval": "month",
                "min_doc_count": 1,
                "order" : { "_count" : "desc" }
              }
            }
          }
        },
        "category" : {
          "terms" : { "field" : "category.raw", "size": 0 }
        },
        "directed" : {
          "terms" : { "field" : "directed.raw", "size": 0 }
        }
      }
    }'
    # response
    {
      "took" : 1911,
      "timed_out" : false,
      "_shards" : {
        "total" : 5,
        "successful" : 5,
        "failed" : 0
      },
      "hits" : {
        "total" : 16,
        "max_score" : 4.9337463,
        "hits" : [ {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "11380",
          "_score" : 4.9337463,
          "fields" : {
            "id" : [ 11380 ]
          }
        }, {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "420923",
          "_score" : 4.766492,
          "fields" : {
            "id" : [ 420923 ]
          }
        }, {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "7112",
          "_score" : 3.8131933,
          "fields" : {
            "id" : [ 7112 ]
          }
        }, {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "474953",
          "_score" : 3.8131933,
          "fields" : {
            "id" : [ 474953 ]
          }
        }, {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "502838",
          "_score" : 3.518057,
          "fields" : {
            "id" : [ 502838 ]
          }
        }, {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "417715",
          "_score" : 3.518057,
          "fields" : {
            "id" : [ 417715 ]
          }
        }, {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "521709",
          "_score" : 2.638543,
          "fields" : {
            "id" : [ 521709 ]
          }
        }, {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "77269",
          "_score" : 2.638543,
          "fields" : {
            "id" : [ 77269 ]
          }
        }, {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "77267",
          "_score" : 2.477974,
          "fields" : {
            "id" : [ 77267 ]
          }
        }, {
          "_index" : "kinopoisk",
          "_type" : "film",
          "_id" : "77265",
          "_score" : 2.477974,
          "fields" : {
            "id" : [ 77265 ]
          }
        } ]
      },
      "aggregations" : {
        "directed" : {
          "doc_count_error_upper_bound" : 0,
          "sum_other_doc_count" : 0,
          "buckets" : [ {
            "key" : "Игорь Масленников",
            "doc_count" : 7
          }, {
            "key" : "Гай Ричи",
            "doc_count" : 2
          }, {
            "key" : "Андрей Кавун",
            "doc_count" : 1
          }, {
            "key" : "Барри Левинсон",
            "doc_count" : 1
          }, {
            "key" : "Бастер Китон",
            "doc_count" : 1
          }, {
            "key" : "Гай Ферленд",
            "doc_count" : 1
          }, {
            "key" : "Джефф Сьергей",
            "doc_count" : 1
          }, {
            "key" : "Джон Полсон",
            "doc_count" : 1
          }, {
            "key" : "Коки Гидройч",
            "doc_count" : 1
          }, {
            "key" : "Пол МакГиган",
            "doc_count" : 1
          }, {
            "key" : "Саймон Селлан Джоунс",
            "doc_count" : 1
          }, {
            "key" : "Сет Манн",
            "doc_count" : 1
          }, {
            "key" : "Спайк Брандт",
            "doc_count" : 1
          }, {
            "key" : "Эрос Лин",
            "doc_count" : 1
          } ]
        },
        "category" : {
          "doc_count_error_upper_bound" : 0,
          "sum_other_doc_count" : 0,
          "buckets" : [ {
            "key" : "детектив",
            "doc_count" : 16
          }, {
            "key" : "криминал",
            "doc_count" : 12
          }, {
            "key" : "триллер",
            "doc_count" : 5
          }, {
            "key" : "драма",
            "doc_count" : 4
          }, {
            "key" : "приключения",
            "doc_count" : 4
          }, {
            "key" : "комедия",
            "doc_count" : 3
          }, {
            "key" : "боевик",
            "doc_count" : 2
          }, {
            "key" : "фэнтези",
            "doc_count" : 2
          }, {
            "key" : "мультфильм",
            "doc_count" : 1
          }, {
            "key" : "семейный",
            "doc_count" : 1
          } ]
        },
        "years" : {
          "buckets" : [ {
            "key_as_string" : "1980-01-01T00:00:00.000Z",
            "key" : 315532800000,
            "doc_count" : 5,
            "months" : {
              "buckets" : [ {
                "key_as_string" : "1980-01-01T00:00:00.000Z",
                "key" : 315532800000,
                "doc_count" : 3
              }, {
                "key_as_string" : "1980-03-01T00:00:00.000Z",
                "key" : 320716800000,
                "doc_count" : 2
              } ]
            }
          }, {
            "key_as_string" : "2010-01-01T00:00:00.000Z",
            "key" : 1262304000000,
            "doc_count" : 2,
            "months" : {
              "buckets" : [ {
                "key_as_string" : "2010-07-01T00:00:00.000Z",
                "key" : 1277942400000,
                "doc_count" : 1
              }, {
                "key_as_string" : "2010-08-01T00:00:00.000Z",
                "key" : 1280620800000,
                "doc_count" : 1
              } ]
            }
          }, {
            "key_as_string" : "2012-01-01T00:00:00.000Z",
            "key" : 1325376000000,
            "doc_count" : 2,
            "months" : {
              "buckets" : [ {
                "key_as_string" : "2012-09-01T00:00:00.000Z",
                "key" : 1346457600000,
                "doc_count" : 1
              }, {
                "key_as_string" : "2012-12-01T00:00:00.000Z",
                "key" : 1354320000000,
                "doc_count" : 1
              } ]
            }
          }, {
            "key_as_string" : "1924-01-01T00:00:00.000Z",
            "key" : -1451692800000,
            "doc_count" : 1,
            "months" : {
              "buckets" : [ {
                "key_as_string" : "1924-04-01T00:00:00.000Z",
                "key" : -1443830400000,
                "doc_count" : 1
              } ]
            }
          }, {
            "key_as_string" : "1983-01-01T00:00:00.000Z",
            "key" : 410227200000,
            "doc_count" : 1,
            "months" : {
              "buckets" : [ {
                "key_as_string" : "1983-06-01T00:00:00.000Z",
                "key" : 423273600000,
                "doc_count" : 1
              } ]
            }
          }, {
            "key_as_string" : "1985-01-01T00:00:00.000Z",
            "key" : 473385600000,
            "doc_count" : 1,
            "months" : {
              "buckets" : [ {
                "key_as_string" : "1985-12-01T00:00:00.000Z",
                "key" : 502243200000,
                "doc_count" : 1
              } ]
            }
          }, {
            "key_as_string" : "1987-01-01T00:00:00.000Z",
            "key" : 536457600000,
            "doc_count" : 1,
            "months" : {
              "buckets" : [ {
                "key_as_string" : "1987-03-01T00:00:00.000Z",
                "key" : 541555200000,
                "doc_count" : 1
              } ]
            }
          }, {
            "key_as_string" : "2004-01-01T00:00:00.000Z",
            "key" : 1072915200000,
            "doc_count" : 1,
            "months" : {
              "buckets" : [ {
                "key_as_string" : "2004-12-01T00:00:00.000Z",
                "key" : 1101859200000,
                "doc_count" : 1
              } ]
            }
          }, {
            "key_as_string" : "2009-01-01T00:00:00.000Z",
            "key" : 1230768000000,
            "doc_count" : 1,
            "months" : {
              "buckets" : [ {
                "key_as_string" : "2009-12-01T00:00:00.000Z",
                "key" : 1259625600000,
                "doc_count" : 1
              } ]
            }
          }, {
            "key_as_string" : "2011-01-01T00:00:00.000Z",
            "key" : 1293840000000,
            "doc_count" : 1,
            "months" : {
              "buckets" : [ {
                "key_as_string" : "2011-12-01T00:00:00.000Z",
                "key" : 1322697600000,
                "doc_count" : 1
              } ]
            }
          } ]
        }
      }
    }
