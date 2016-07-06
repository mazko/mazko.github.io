title: ElasticSearch - одностраничное приложение на Angular2
category: JavaScript
tags: Elastic, Angular2

Вооружившись знаниями приобретёнными в предыдущем материале по [ElasticSearch]({filename}../../admin/2016-06-25-elastic-play/2016-06-25-elastic-play.md) самое время сделать что-то полезное. В данном материале мы напишем [одностраничное](https://ru.wikipedia.org/wiki/%D0%9E%D0%B4%D0%BD%D0%BE%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B8%D1%87%D0%BD%D0%BE%D0%B5_%D0%BF%D1%80%D0%B8%D0%BB%D0%BE%D0%B6%D0%B5%D0%BD%D0%B8%D0%B5){:rel="nofollow"} приложение (SPA) на [Angular2](https://angular.io/){:rel="nofollow"}. Это будет полнотекстовый поиск фильмов с подсказками, подсветкой и агрегацией результатов по актёрам/режиссёрам/жанрам и датам. Писать SPA будем на [TypeScript](https://www.typescriptlang.org/){:rel="nofollow"} - это который JavaScript нового поколения плюс строгая типизация, умеющая обнаруживать многие типичные ошибки в коде программы ещё на этапе сборки приложения и соотвественно вежливо сообщать об этом ещё до неловкого момента *ой, не работает*.

<!-- cd ./dist/ && find . -type f | sort | xargs -I{} -n1 echo -e '<a href="\x7Battach\x7Ddist/{}"></a>' | xclip -selection clipboard && cd - -->

<!-- sed -i '/<base href="\/">/d' ./dist/index.html -->
 
<!-- 
<a href="{attach}dist/./app/app.component.css"></a>
<a href="{attach}dist/./app/app.component.html"></a>
<a href="{attach}dist/./app/films-search/aggregations/aggregations.component.css"></a>
<a href="{attach}dist/./app/films-search/aggregations/aggregations.component.html"></a>
<a href="{attach}dist/./app/films-search/auto-complete/auto-complete.component.css"></a>
<a href="{attach}dist/./app/films-search/auto-complete/auto-complete.component.html"></a>
<a href="{attach}dist/./app/films-search/films-list/films-list.component.css"></a>
<a href="{attach}dist/./app/films-search/films-list/films-list.component.html"></a>
<a href="{attach}dist/./app/films-search/films-search.component.css"></a>
<a href="{attach}dist/./app/films-search/films-search.component.html"></a>
<a href="{attach}dist/./app/films-search/hi/hi.component.css"></a>
<a href="{attach}dist/./app/films-search/hi/hi.component.html"></a>
<a href="{attach}dist/./favicon.ico"></a>
<a href="{attach}dist/./index.html"></a>
<a href="{attach}dist/./main.js"></a>
<a href="{attach}dist/./system-config.js"></a>
<a href="{attach}dist/./vendor/es6-shim/es6-shim.js"></a>
<a href="{attach}dist/./vendor/reflect-metadata/Reflect.js"></a>
<a href="{attach}dist/./vendor/reflect-metadata/reflect-metadata.d.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/Reflect.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/test/harness.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/test/reflect/reflect-decorate.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/test/reflect/reflect-definemetadata.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/test/reflect/reflect-deletemetadata.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/test/reflect/reflect-getmetadatakeys.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/test/reflect/reflect-getmetadata.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/test/reflect/reflect-getownmetadatakeys.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/test/reflect/reflect-getownmetadata.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/test/reflect/reflect-hasmetadata.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/test/reflect/reflect-hasownmetadata.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/test/reflect/reflect-metadata.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/test/run.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/test/spec.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/typings.d.ts"></a>
<a href="{attach}dist/./vendor/reflect-metadata/typings/node.d.ts"></a>
<a href="{attach}dist/./vendor/systemjs/dist/system.src.js"></a>
<a href="{attach}dist/./vendor/zone.js/dist/zone.js"></a>
-->

[Исходники]({attach}elastic-angular2.zip) | [Демо]({attach}dist/index.html)

[comment]: <> (byzanz-record -c -e 'firefox --private-window http://localhost:8000/blog/posts/2016/07/06/elasticsearch-odnostranichnoe-prilozhenie-na-angular2/dist/index.html' --x=66 --y=26 --delay 5 ui.gif)

![screenshot]({attach}ui.gif){:style="width:100%; border:1px solid #ddd;"}

Очень простой и быстрый способ начать работать с Angular2 - воспользоваться генератором проектов [angular-cli](https://github.com/angular/angular-cli){:rel="nofollow"}: 

    :::bash
    ~: pip install nodeenv
    ~: mkdir angular2-elastic-tutorial && cd $_
    ~: nodeenv env --prebuilt
    ~: . env/bin/activate
    (env)~: node -v 
    v6.3.0
    (env)~: npm -v
    3.10.3
    (env)~: npm install -g angular-cli
    (env)~: ng version
    angular-cli: 1.0.0-beta.9
    node: 6.3.0
    os: linux x64
    (env)~: ng new elastic && cd $_
    (env)~: tree -I node_modules
    .
    ├── angular-cli-build.js
    ├── angular-cli.json
    ├── config
    │   ├── environment.dev.ts
    │   ├── environment.js
    │   ├── environment.prod.ts
    │   ├── karma.conf.js
    │   ├── karma-test-shim.js
    │   └── protractor.conf.js
    ├── e2e
    │   ├── app.e2e-spec.ts
    │   ├── app.po.ts
    │   ├── tsconfig.json
    │   └── typings.d.ts
    ├── package.json
    ├── public
    ├── README.md
    ├── src
    │   ├── app
    │   │   ├── app.component.css
    │   │   ├── app.component.html
    │   │   ├── app.component.spec.ts
    │   │   ├── app.component.ts
    │   │   ├── environment.ts
    │   │   ├── index.ts
    │   │   └── shared
    │   │       └── index.ts
    │   ├── favicon.ico
    │   ├── index.html
    │   ├── main.ts
    │   ├── system-config.ts
    │   ├── tsconfig.json
    │   └── typings.d.ts
    ├── tslint.json
    ├── typings
    │   ├── browser
    │   │   └── ambient
    │   │       ├── angular-protractor
    │   │       │   └── index.d.ts
    │   │       ├── es6-shim
    │   │       │   └── index.d.ts
    │   │       ├── jasmine
    │   │       │   └── index.d.ts
    │   │       └── selenium-webdriver
    │   │           └── index.d.ts
    │   ├── browser.d.ts
    │   ├── main
    │   │   └── ambient
    │   │       ├── angular-protractor
    │   │       │   └── index.d.ts
    │   │       ├── es6-shim
    │   │       │   └── index.d.ts
    │   │       ├── jasmine
    │   │       │   └── index.d.ts
    │   │       └── selenium-webdriver
    │   │           └── index.d.ts
    │   └── main.d.ts
    └── typings.json

    19 directories, 39 files

Вот такая вот структура у нового Angular2 проекта. Тут предусмотрено наличие [юнит-тестов](https://angular.io/docs/ts/latest/guide/testing.html){:rel="nofollow"}:

    :::bash
    (env)~: ng test --watch=false
    Executed 2 of 2 SUCCESS

Запуск в режиме разработки:

    :::bash
    (env)~: ng serve

Сгенерируем компонент для поиска и отображения фильмов а также сервис для получения соответствующих данных из ElasticSearch:

    :::bash
    (env)~: ng generate component FilmsSearch
      create src/app/films-search/films-search.component.css
      create src/app/films-search/films-search.component.html
      create src/app/films-search/films-search.component.spec.ts
      create src/app/films-search/films-search.component.ts
      create src/app/films-search/index.ts
    (env)~: ng generate service films-search/Elastic
      create src/app/films-search/elastic.service.spec.ts
      create src/app/films-search/elastic.service.ts

Сервис Elastic и юнит тесты к нему:

*src/app/films-search/elastic.service.spec.ts*

    :::ts
    import {
      beforeEach, beforeEachProviders,
      describe, xdescribe,
      expect, it, xit,
      async, inject
    } from '@angular/core/testing';

    import { MockBackend, MockConnection } from '@angular/http/testing';
    import { Http } from '@angular/http';
    import { provide } from '@angular/core';
    import { BaseRequestOptions, Response, ResponseOptions } from '@angular/http';

    import { ElasticService } from './elastic.service';

    describe('Elastic Service', () => {

      beforeEachProviders(() => [
        ElasticService,
        BaseRequestOptions,
        MockBackend,
        provide(Http, {
          useFactory: (backend: MockBackend, defaultOptions: BaseRequestOptions) => {
            return new Http(backend, defaultOptions);
          },
          deps: [MockBackend, BaseRequestOptions]
        })
      ]);

      beforeEach(inject([MockBackend], (backend: MockBackend) => {
        const baseResponse = new Response(new ResponseOptions({
          body: JSON.stringify({
            hits: {
              total : 42,
              hits: [
                { fields : { rate : [ 8.042 ], id : [ 409640 ] } },
                { fields : { rate : [ 7.943 ], id : [ 153013 ] } }
              ]
            }
          }) 
        }));
        backend.connections.subscribe((c: MockConnection) => c.mockRespond(baseResponse));
      }));

      it('should elastic search',
        inject([ElasticService], (elk: ElasticService) => 
          elk.search().then(chunk => {
            expect(chunk.items.length).toBe(2);
            expect(chunk.total).toBe(42);
            expect(chunk.items[1].id).toEqual([153013]);
          })
        )
      );
    });

*src/app/films-search/elastic.service.ts*

    :::ts
    import { Injectable } from '@angular/core';
    import { Http, URLSearchParams } from '@angular/http';
    import 'rxjs/add/operator/toPromise';

    // Elastic docs:
    // Field values fetched from the document it self 
    // are always returned as an array.
    export interface IFilm {
      id: number[];
      name: string[];
      date: string[];
      description: string[];
      rate: number[];
      starring: string[];
      category: string[];
      directed: string[];
    }

    export interface IChunk<T> {
      items: T[];
      total: number;
    }

    const ELASTIC_URL = '//localhost:9200/kinopoisk/';

    interface ISearchKwargs {
      from?: number; size?: number; /* paginating */
      fields?: string[]; /* full text searching fields */
    }

    @Injectable()
    export class ElasticService {

      constructor(private _http : Http){}

      search(kwargs? : ISearchKwargs) : Promise<IChunk<IFilm>> {
        const kwargsDefs : ISearchKwargs = {
          from: 0, size: 5, fields: [ "name", "description" ]
        };
        kwargs = Object.assign(kwargsDefs, kwargs);

        const params = new URLSearchParams();
        // Elastic docs: 
        // For libraries that don’t accept a request body 
        // for non-POST requests, you can pass the request 
        // body as the source query string parameter instead.
        params.set('source', JSON.stringify({
          'from': kwargs.from,
          'size': kwargs.size,
          "fields" : [
            "id", "name", "date", 
            "description", "rate", 
            "starring", "category", "directed"],
          "query" : { "match_all": {} },
          "sort" : [
            {"rate" : {"order" : "desc"} }
           ],
        }));
        return this._http
          .get(ELASTIC_URL + 'film/_search', { search: params })
          .toPromise()
          .then(response => {
            const { hits } = response.json();
            return {
              items: hits.hits.map(hit => hit.fields),
              total: hits.total
            };
          });
      }
    }

Запуск тестов:

    :::bash
    (env)~: ng test --watch=false
    Executed 3 of 3 SUCCESS

Компонент FilmsSearch и юнит тесты:

*src/app/films-search/films-search.component.spec.ts*

    :::ts
    import { provide } from '@angular/core';

    import {
      beforeEach, beforeEachProviders,
      describe, xdescribe,
      expect, it, xit,
      async, inject
    } from '@angular/core/testing';

    import { TestComponentBuilder } from '@angular/compiler/testing'

    import { FilmsSearchComponent } from './films-search.component';
    import { ElasticService } from './elastic.service';

    class MockElasticService {

      search() {
        return Promise.resolve({
          items: [
            { 
              id: [409640],
              name: ["Касл (сериал 2009 – ...)"],
              rate: 8.042
            },
            { 
              id: [153013],
              name: ["Звездный крейсер Галактика (сериал 2004 – 2009)"],
              rate: 7.943
            }
          ],
          total: 42
        });
      }
    }

    describe('Component: FilmsSearch', () => {
      let tcb:TestComponentBuilder;
      
      //setup
      beforeEach(inject([TestComponentBuilder], _tcb => 
        tcb = _tcb.overrideProviders(
          FilmsSearchComponent,
          [provide(ElasticService, { useClass: MockElasticService })]
        )
      ));

      //specs
      it('should render films', () =>
        tcb.createAsync(FilmsSearchComponent)
        .then(fixture => {
          const element = fixture.nativeElement;
          fixture.detectChanges();
          expect(element.querySelectorAll('div').length).toBe(2);
          expect(element.querySelector('div p a').innerText).toBe('8.042');
        })
      );

    });

*src/app/films-search/films-search.component.ts*

    :::ts
    import { Component } from '@angular/core';
    import { ElasticService, IFilm } from './elastic.service';

    @Component({
      moduleId: module.id,
      selector: 'films-search',
      templateUrl: 'films-search.component.html',
      styleUrls: ['films-search.component.css'],
      providers: [ElasticService]
    })
    export class FilmsSearchComponent {

      films: IFilm[];

      constructor(elk : ElasticService) {
        elk.search({
          from: 0, size: 5
        }).then(chunk => {
          this.films = chunk.items;
        }).catch(e => alert(e));
      }
    }

*src/app/films-search/films-search.component.html*

    :::text
    <div *ngFor="let film of films">
      <p>
        <b>Название: </b>{{film.name}} | 
        <a href="https://www.kinopoisk.ru/film/{{film.id}}/">{{film.rate}}</a> | 
        <span *ngFor="let date of film.date">
          {{date | date}}
        </span>
      </p>
      <p>
        <b>Режиссёр: </b>{{film.directed?.join(' | ')}}
      </p>
      <p>
        <b>Жанр: </b>{{film.category?.join(' | ')}}
      </p>
      <p>
        <b>Актёры: </b>{{film.starring?.join(' | ')}}
      </p>
      <p>
        <b>Описание: </b>{{film.description}}
      </p>
      <hr/>
    </div>

Тесты:

    :::bash
    (env)~: ng test --watch=false
    Executed 4 of 4 SUCCESS

Осталось совсем чуть-чуть, чтобы увидеть результаты в браузере:

*src/app/app.component.html*

    :::text
    <films-search>

*src/app/app.component.ts*

    :::ts
    import { Component } from '@angular/core';
    import { FilmsSearchComponent } from './films-search';

    @Component({
      moduleId: module.id,
      selector: 'app-root',
      templateUrl: 'app.component.html',
      styleUrls: ['app.component.css'],
      directives: [FilmsSearchComponent]
    })
    export class AppComponent {}

*src/main.ts*

    :::ts
    import { bootstrap } from '@angular/platform-browser-dynamic';
    import { enableProdMode } from '@angular/core';
    import { AppComponent, environment } from './app/';

    import { HTTP_PROVIDERS } from '@angular/http';

    if (environment.production) {
      enableProdMode();
    }

    bootstrap(AppComponent, [ HTTP_PROVIDERS ]);

Вуаля !

![screenshot]({attach}hello-world-a2.png){:style="width:100%; border:1px solid #ddd;"}

Дальше интересней. Дополним Elastic сервис подсказками, агрегацией, подсветкой и.т.д.:

*src/app/films-search/elastic.service.ts*

    :::ts
    import { Injectable } from '@angular/core';
    import { Http, URLSearchParams } from '@angular/http';
    import 'rxjs/add/operator/toPromise';

    export interface IFilm {
      id: number[];
      name: string[];
      date: string[];
      description: string[];
      rate: number[];
      starring: string[];
      category: string[];
      directed: string[];
    }

    export interface IChunk<T> {
      items: T[];
      total: number;
    }

    export interface IAggs {
      directors: Array<{key:string; doc_count:number}>;
      categories: Array<{key:string; doc_count:number}>;
      stars: Array<{key:string; doc_count:number}>;
      years: Array<{key:number; doc_count:number; 
        months?:Array<{key:number; doc_count:number}>}>;
    }

    const ELASTIC_URL = '//localhost:9200/kinopoisk/';

    interface ISearchKwargs {
      q?: string; from?: number; size?: number; fields?: string[];
      year?: number; month?: number;
      star?: string, director?: string, category?: string
    }

    @Injectable()
    export class ElasticService {

      constructor(private _http : Http){}

      suggest(a:string, size:number=10) : Promise<string[]> {
        const params = new URLSearchParams();
        params.set('source', JSON.stringify({
          "kino" : {
            "text" : a,
            "completion" : {
              "field" : "suggest",
              "size": size
            }
          }
        }));
        return this._http
          .get(ELASTIC_URL + '_suggest', { search: params })
          .toPromise()
          .then(response => {
            const opts = response.json().kino[0].options;
            return opts.map(opt => opt.text);
          });
      }

      search(kwargs? : ISearchKwargs) : Promise<{chunk:IChunk<IFilm>; aggs:IAggs}> {
        const kwargsDefs : ISearchKwargs = {
          from: 0, size: 5, fields: [ "name", "description" ]
        };
        kwargs = Object.assign(kwargsDefs, kwargs);

        const params = new URLSearchParams();
        params.set('source', JSON.stringify({
          'from': kwargs.from,
          'size': kwargs.size,
          "fields" : [
            "id", "name", "date", 
            "description", "rate", 
            "starring", "category", "directed"],
          "query" : {
            "bool": {
              "must": [
                kwargs.q 
                  ? { "query_string" : {
                        "query": kwargs.q,
                        "fields": kwargs.fields,
                        "default_operator": "and"
                      }
                    } 
                  : { "match_all": {} },
              ],
              "filter": [
                kwargs.year
                  ? {
                    "range" : {
                      "date" : {
                        "gte" : kwargs.month >= 0 ? kwargs.year + "-" + kwargs.month : kwargs.year,
                        "lt" : kwargs.year + (kwargs.month >= 0 ? "-" + kwargs.month + "||+1M" : "||+1y"),
                        "format": "yyyy-MM||yyyy"
                      }
                    }
                  }
                  : null,
               kwargs.category 
                 ? {
                   "match": {
                     "category.raw": kwargs.category
                   }
                 } : null,
               kwargs.director 
                 ? {
                   "match": {
                     "directed.raw": kwargs.director
                   }
                 } : null,
               kwargs.star 
                 ? {
                   "match": {
                     "starring.raw": kwargs.star
                   }
                 } : null,
              ].filter(v => v !== null)
            }
          },
          "highlight" : {
            "pre_tags" : ["[mazko.github.io]"],
            "post_tags" : ["[/mazko.github.io]"],
            "fields" : kwargs.fields.reduce(
              (result, item) => {
                result[item] = {
                  "fragment_size" : 333
                };
                return result;
              }, {})
          },
          "sort" : [
            {"rate" : {"order" : "desc"} }
           ],
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
            "categories" : {
              "terms" : { "field" : "category.raw", "size": 1000 }
            },
            "directors" : {
              "terms" : { "field" : "directed.raw", "size": 1000 }
            },
            "stars" : {
              "terms" : { "field" : "starring.raw", "size": 1000 }
            }
          }
        }));
        return this._http
          .get(ELASTIC_URL + 'film/_search', { search: params })
          .toPromise()
          .then(response => {
            const { hits, aggregations } = response.json();
            const chunk : IChunk<IFilm> = {
              items: hits.hits.map(
                hit => Object.assign(hit.fields, hit.highlight)),
              total: hits.total
            };
            const aggs : IAggs = {
              directors: aggregations.directors.buckets,
              categories: aggregations.categories.buckets,
              stars: aggregations.stars.buckets,
              years: aggregations.years.buckets.map(y => {
                return {
                  doc_count: y.doc_count, 
                  key: new Date(y.key).getFullYear(),
                  months: y.months.buckets.map(m => {
                    return {
                      doc_count: m.doc_count, 
                      key: new Date(m.key).getMonth() + 1
                    }
                  })
                }
              })
            };
            return {chunk, aggs};
          });
      }
    }

Реальное Angular2 приложение состоит из множества компонентов, которые могут передавать данные как от родителя к дочернему элементу так и наоборот. Например компонент FilmsList получает данные от родителя в поле films и в свою очередь передаёт свои данные в компонент подсветки Hi: 

    :::bash
    (env)~: ng generate component films-search/FilmsList
      create src/app/films-search/films-list/films-list.component.css
      create src/app/films-search/films-list/films-list.component.html
      create src/app/films-search/films-list/films-list.component.spec.ts
      create src/app/films-search/films-list/films-list.component.ts
      create src/app/films-search/films-list/index.ts

*src/app/films-search/films-list/films-list.component.ts*

    :::ts
    import { Component, Input } from '@angular/core';
    import { IFilm } from '../elastic.service';
    import { HiComponent } from '../hi';

    @Component({
      moduleId: module.id,
      selector: 'films-list',
      templateUrl: 'films-list.component.html',
      styleUrls: ['films-list.component.css'],
      directives: [HiComponent]
    })
    export class FilmsListComponent {

      @Input() films: IFilm[];

    }

*src/app/films-search/films-list/films-list.component.html*

    :::text
    <div *ngFor="let film of films">
      <hr/>
      <p>
        <b>Название: </b><hi [content]="film.name"></hi> | 
        <a href="https://www.kinopoisk.ru/film/{{film.id}}/">{{film.rate}}</a> | 
        <span *ngFor="let date of film.date">
          {{date | date}}
        </span>
      </p>
      <p>
        <b>Режиссёр: </b>{{film.directed?.join(' | ')}}
      </p>
      <p>
        <b>Жанр: </b>{{film.category?.join(' | ')}}
      </p>
      <p>
        <b>Актёры: </b>{{film.starring?.join(' | ')}}
      </p>
      <p>
        <b>Описание: </b><hi [content]="film.description?.join(' ... ')"></hi>
      </p>
    </div>

Компонент Hi:

    :::bash
    (env)~: ng generate component films-search/hi
      create src/app/films-search/hi/hi.component.css
      create src/app/films-search/hi/hi.component.html
      create src/app/films-search/hi/hi.component.spec.ts
      create src/app/films-search/hi/hi.component.ts
      create src/app/films-search/hi/index.ts

*src/app/films-search/hi/hi.component.ts*

    :::ts
    import { Component, Input, ViewChild, AfterViewInit } from '@angular/core';

    @Component({
      moduleId: module.id,
      selector: 'hi',
      templateUrl: 'hi.component.html',
      styleUrls: ['hi.component.css']
    })
    export class HiComponent implements AfterViewInit {

      @Input() content: string;

      @ViewChild('hi') hi;

      ngAfterViewInit() {
        const hi = this.hi.nativeElement;
        hi.innerHTML = hi.innerHTML.replace(
            /\[mazko\.github\.io\](.*?)\[\/mazko\.github\.io\]/g, 
            "<b style=\"color:red;\">$1</b>");
      }
    }

*src/app/films-search/hi/hi.component.html*

    :::text
    <span #hi>{{content}}</span>

Поле ввода поискового запроса в свою очередь уже отсылает данные родителю - событие q_change:

    :::bash
    (env)~: ng generate component films-search/AutoComplete
      create src/app/films-search/auto-complete/auto-complete.component.css
      create src/app/films-search/auto-complete/auto-complete.component.html
      create src/app/films-search/auto-complete/auto-complete.component.spec.ts
      create src/app/films-search/auto-complete/auto-complete.component.ts
      create src/app/films-search/auto-complete/index.ts

*src/app/films-search/auto-complete/auto-complete.component.ts*

    :::ts
    import { Component, Output, EventEmitter, ViewChild, ElementRef } from '@angular/core';
    import { Subject }        from 'rxjs/Subject';
    import 'rxjs/add/operator/debounceTime';
    import 'rxjs/add/operator/distinctUntilChanged';
    import 'rxjs/add/operator/switchMap';
    import { ElasticService } from '../elastic.service';

    @Component({
      moduleId: module.id,
      selector: 'auto-complete',
      host: {
        '(document:click)': 'handleClick($event)',
      },
      templateUrl: 'auto-complete.component.html',
      providers: [ElasticService],
      styleUrls: ['auto-complete.component.css']
    })
    export class AutoCompleteComponent  {

      @Output() q_change = new EventEmitter<string>();
      @ViewChild('menu') private menuRef;

      private searchTermStream = new Subject<string>();

      constructor(private _es : ElasticService) {
        this.searchTermStream
          .debounceTime(333)
          .distinctUntilChanged()
          .switchMap(q => q 
            ? this._es.suggest(q).catch(e => Promise.resolve([])) 
            : Promise.resolve([]))
          .subscribe(suggestions => {
             this.suggestions = suggestions;
          });
      }

      suggestions: string[];
      query: string;

      handleClear() {
        this.suggestions = [];
        this.searchTermStream.next('');
      }

      handleQuery() {
        this.q_change.emit(this.query);
      }

      handleKey(keyCode: number) {
        if ([27, 13].indexOf(keyCode) > -1) {
          this.handleClear();
        } else {
          this.searchTermStream.next(this.query);
        }
      }

      private isEventInsideElement(event:Event, child:ElementRef) : boolean {
        return child.nativeElement.contains(event.target);
      }

      handleClick(event:MouseEvent) {
        if (this.isEventInsideElement(event, this.menuRef)) {
          this.query = (<HTMLElement>event.target).dataset['val'];
          this.handleQuery();
        } 
        this.handleClear();
      }
    }

*src/app/films-search/auto-complete/auto-complete.component.html*

    :::text
    <span>
      <input
        [(ngModel)]=query 
        (keyup)=handleKey($event.keyCode) 
        (keyup.enter)=handleQuery() 
        type="text" placeholder="пример:космос" autocomplete="off">
    </span>
    <ul #menu>
      <li *ngFor="let suggest of suggestions" [attr.data-val]=suggest>
        {{suggest}}
      </li>
    </ul>

*src/app/films-search/auto-complete/auto-complete.component.css*

    :::css
    input {
      text-align: center;
      flex-grow: 1;
      font-size: inherit;
    }

    span {
      display: flex;
      height: 100%;
    }

    ul {
      padding: 0px;
      margin: 0px;
      border: solid 1px #f1f1f1;
      position: absolute;
      background: #FFF;
    }

    ul li {
      list-style: none;
      padding: 5px;
      margin: 0px;
      color: #7E7E7E;
      cursor: pointer;
    }

    ul li:hover {
      background-color: #f1f1f1;
      color: #000;
    }

В компонент Aggregations присутствуют оба случая:

    :::bash
    (env)~: ng generate component films-search/Aggregations
      create src/app/films-search/aggregations/aggregations.component.css
      create src/app/films-search/aggregations/aggregations.component.html
      create src/app/films-search/aggregations/aggregations.component.spec.ts
      create src/app/films-search/aggregations/aggregations.component.ts
      create src/app/films-search/aggregations/index.ts

*src/app/films-search/aggregations/aggregations.component.ts*

    :::ts
    import { Component, Output, EventEmitter, Input } from '@angular/core';
    import { IAggs } from '../elastic.service';

    export class IAggsFilter {
      year: number;
      month: number;
      star: string;
      category: string;
      director: string;
    }

    @Component({
      moduleId: module.id,
      selector: 'aggregations',
      templateUrl: 'aggregations.component.html',
      styleUrls: ['aggregations.component.css']
    })
    export class AggregationsComponent {

      @Output() aggs_change = new EventEmitter<IAggsFilter>();

      @Input() set data(aggs : IAggs) {
        if (!aggs) return;
        // Flatten array easier to work in Angular2
        // TODO: strong typing <reduce>
        aggs.years = aggs.years.reduce(
          (flat, toFlat) => [
            ...flat,
            { year: toFlat.key, doc_count: toFlat.doc_count },
            ...toFlat.months.map(m => {
              return {
                year: toFlat.key,
                month: m.key,
                doc_count: m.doc_count
              }
            })
          ], []);

        if (this.search_star && aggs.stars.length === 0) {
          aggs.stars = [{key: this.search_star, doc_count: 0}];
        }
        if (this.search_category && aggs.categories.length === 0) {
          aggs.categories = [{key: this.search_category, doc_count: 0}];
        }
        if (this.search_director && aggs.directors.length === 0) {
          aggs.directors = [{key: this.search_director, doc_count: 0}];
        }
        // TODO: strong typing <any>
        if (this.search_month && aggs.years.length === 0) {
          aggs.years = [
            <any>{year: this.search_year, doc_count: 0},
            <any>{year: this.search_year, month: this.search_month, doc_count: 0}
          ];
        } else if (this.search_year && aggs.years.length === 0) {
          aggs.years = [<any>{year: this.search_year, doc_count: 0}];
        }

        this.aggs = aggs;
       }

      aggs:IAggs;

      search_year: number;
      search_month: number;
      search_star: string;
      search_category: string;
      search_director: string;

      private _emit() {
        this.aggs_change.emit({
          year: this.search_year,
          month: this.search_month,
          star: this.search_star,
          category: this.search_category,
          director: this.search_director
        });
      }

      handleYM(index:string) {
        const idx = Number(index);
        if (idx >= 0) {
          this.search_year = this.aggs.years[idx]['year'];
          this.search_month = this.aggs.years[idx]['month'];
        } else {
          this.search_year = this.search_month = undefined;
        }
        this._emit();
      }

      handleStar(star:string) {
        this.search_star = star;
        this._emit();
      }

      handleDirector(dir:string) {
        this.search_director= dir;
        this._emit();
      }

      handleCaterory(cat:string) {
        this.search_category = cat;
        this._emit();
      }
    }

*src/app/films-search/aggregations/aggregations.component.html*

    :::text
    <span>
      <select #ym (change)="handleYM(ym.value)">
        <option value='-1'></option>
        <option *ngFor="let ym of aggs?.years ; let idx = index" 
          [value]="idx" [attr.selected]=
            "(ym.month === search_month && ym.year === search_year) ? 'selected' : null">
          {{ym.month >= 0 ? '-> ' + ("00" + ym.month).slice(-2) : ym.year}} | {{ym.doc_count}}
        </option>
      </select>

      <select #star (change)="handleStar(star.value)">
        <option></option>
        <option *ngFor="let star of aggs?.stars" [value]="star.key"
          [attr.selected]="star.key === search_star ? 'selected' : null">
          {{star.doc_count}} | {{star.key}}
        </option>
      </select>

      <select #dir (change)="handleDirector(dir.value)">
        <option></option>
        <option *ngFor="let dir of aggs?.directors" [value]="dir.key"
          [attr.selected]="dir.key === search_director ? 'selected' : null">
          {{dir.doc_count}} | {{dir.key}}
        </option>
      </select>

      <select #cat (change)="handleCaterory(cat.value)">
        <option></option>
        <option *ngFor="let cat of aggs?.categories" [value]="cat.key"
          [attr.selected]="cat.key === search_category ? 'selected' : null">
          {{cat.doc_count}} | {{cat.key}}
        </option>
      </select>
    </span>

*src/app/films-search/aggregations/aggregations.component.css*

    :::css
    span {
      display: flex;
      height: 100%;
    }

    select {
      font-size: inherit;
      text-overflow: ellipsis;
    }

    select {
      flex-grow: 1;
    }

    select:not(:first-of-type) {
      margin-left: 7px;
    }

Последний штрих - связать всё в одном компоненте FilmsSearch:

*src/app/films-search/films-search.component.ts*

    :::ts
    import { Component, OnInit } from '@angular/core';
    import { ElasticService, IFilm, IAggs } from './elastic.service';
    import { FilmsListComponent } from './films-list';
    import { AutoCompleteComponent } from './auto-complete';
    import { AggregationsComponent, IAggsFilter } from './aggregations';

    @Component({
      moduleId: module.id,
      selector: 'films-search',
      templateUrl: 'films-search.component.html',
      styleUrls: ['films-search.component.css'],
      providers: [ElasticService],
      directives: [FilmsListComponent, AutoCompleteComponent, AggregationsComponent]
    })
    export class FilmsSearchComponent implements OnInit {

      films: IFilm[];
      films_per_page: number = 5;
      aggs: IAggs;
      total_pages: number;
      current_page: number;
      search_query: string;
      search_aggs: IAggsFilter;

      is_fetching_state: boolean;

      constructor(private _es : ElasticService){}

      private _search() {
        const from = (this.current_page - 1) * this.films_per_page;
        this.is_fetching_state = true;
        const filter = this.search_aggs || <IAggsFilter>{};
        this._es.search({
          q: this.search_query, 
          from, size: this.films_per_page,
          year: filter.year, month: filter.month,
          star: filter.star, category: filter.category, 
          director: filter.director
        }).then(({chunk, aggs}) => {
          this.is_fetching_state = false;
          this.films = chunk.items;
          this.total_pages = Math.ceil(chunk.total / this.films_per_page);
          this.aggs = aggs;
        }).catch(e => alert(e));
      }

      handlePerPage(value:string) {
        this.films_per_page = Number(value);
        this.handleQuery(this.search_query);
      }

      handleNextPage() {
        this.current_page += 1;
        this._search();
      }

      handlePrevPage() {
        this.current_page -= 1;
        this._search();
      }

      handleQuery(query? : string) {
        this.search_query = query;
        this.current_page = 1;
        this._search();
      }

      ngOnInit() {
        this.handleQuery();
      }

      handleAggs(filter : IAggsFilter) {
        this.search_aggs = filter;
        this.handleQuery(this.search_query);
      }
    }

*src/app/films-search/films-search.component.html*

    :::text
    <div>
      <p>
        <auto-complete (q_change)="handleQuery($event)"></auto-complete>

        <select #perPage 
          [disabled]=is_fetching_state
          (change)="handlePerPage(perPage.value)">
          <option *ngFor="let p of [3, 5, 10, 25]"
            [attr.selected]="p === films_per_page ? 'selected' : null">
            {{p}}
          </option>
        </select>

        <button *ngIf="current_page > 1" 
          [disabled]=is_fetching_state
          (click)="handlePrevPage()">{{'<'}}
        </button>
        <button *ngIf="current_page < total_pages"
          [disabled]=is_fetching_state
          (click)="handleNextPage()">{{'>'}}
        </button>
        <span *ngIf=total_pages>Страница {{current_page}} из {{total_pages}}</span>
      </p>

      <p>
        <aggregations [data]=aggs (aggs_change)="handleAggs($event)"></aggregations>
      </p>

      <films-list [films]=films></films-list> 
    </div>

*src/app/films-search/films-search.component.css*

    :::css
    div {
      font-size: 18px;
    }

    p {
      display: flex;
    }

    auto-complete, aggregations {
      flex-grow: 1;
    }

    button {
      margin-left: 7px;
      align-self: stretch;
      font-size: inherit;
    }

    span {
      margin-left: 5px;
      align-self: center;
    }

    select {
      margin-left: 7px;
      font-size: inherit;
      text-overflow: ellipsis;
    }

Сборка для демо на картинке:

    :::bash
    (env)~: ng build -prod