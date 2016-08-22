title: ElasticSearch - одностраничное приложение на ReactJS
category: JavaScript
tags: Elastic, React


Продолжая тему [ElasticSearch]({filename}../../admin/2016-06-25-elastic-play/2016-06-25-elastic-play.md) и [одностраничных](https://ru.wikipedia.org/wiki/%D0%9E%D0%B4%D0%BD%D0%BE%D1%81%D1%82%D1%80%D0%B0%D0%BD%D0%B8%D1%87%D0%BD%D0%BE%D0%B5_%D0%BF%D1%80%D0%B8%D0%BB%D0%BE%D0%B6%D0%B5%D0%BD%D0%B8%D0%B5){:rel="nofollow"} приложений (SPA) напишем полнотекстовый поиск фильмов с подсказками, подсветкой и агрегацией результатов по актёрам/режиссёрам/жанрам и датам на [ReactJS](https://facebook.github.io/react/){:rel="nofollow"} - идентичный тому, что уже был реализован ранее на [Angular2]({filename}../2016-07-06-elastic-angular2/2016-07-06-elastic-angular2.md). Для работы с демо из браузера нужно в [ElasticSearch]({filename}../../admin/2016-06-25-elastic-play/2016-06-25-elastic-play.md) нужно настроить ```http.cors``` для **http://mazko.github.io**, например ```allow-origin: /https?:\/\/mazko\.github\.io/```

<!-- cd ./dist/ && find . -type f | sort | xargs -I{} -n1 echo -e '<a href="\x7Battach\x7Ddist/{}"></a>' | xclip -selection clipboard && cd - -->
 
<!-- 
<a href="{attach}dist/./bundle.js"></a>
<a href="{attach}dist/./bundle.js.map"></a>
<a href="{attach}dist/./favicon.ico"></a>
<a href="{attach}dist/./index.html"></a>
-->

[Исходники]({attach}react-elastic-example.zip) | [Демо]({attach}dist/index.html)

[comment]: <> (byzanz-record -c --x=74 --y=26 --delay 5 -d 44 ui.gif)

![screenshot]({attach}ui.gif){:style="width:100%; border:1px solid #ddd;"}

React, в отличие от Angular, это только библиотека, поэтому потребуются дополнительные телодвижения для старта. Собирать \*.js файлы будет [webpack](https://webpack.github.io/){:rel="nofollow"}: 

    :::bash
    ~: mkdir react-elastic-example && cd $_
    ~: npm init -y
    ~: npm i --save-dev \
          babel-loader babel-preset-es2015 babel-preset-react \
          css-loader react react-dom style-loader \
          webpack webpack-dev-server isomorphic-fetch

*webpack.config.js*

    :::js
    module.exports = {
       entry: './src/main.js',
      
       output: {
          path:'./dist',
          filename: 'bundle.js',
       },

       devtool: 'source-map',
      
       devServer: {
          inline: true,
          port: 8080
       },
      
       module: {
          loaders: [
             {
                test: /\.jsx?$/,
                exclude: /node_modules/,
                loader: 'babel',
                query: {
                   presets: ['es2015', 'react']
                }
             },
             { 
                test: /\.css$/, 
                loader: "style-loader!css-loader?modules=true" 
             }
          ]
       }
    };

Запуск в режиме разработки:

    :::bash
    ~: ./node_modules/webpack-dev-server/bin/webpack-dev-server.js --hot --content-base ./src/

Начнем с сервиса для получения данных из ElasticSearch:

*src/films-search/elastic.service.js*

    :::js
    import fetch from 'isomorphic-fetch';

    const ELASTIC_URL = 'http://localhost:9200/kinopoisk/';

    function search(kwargs) {
      const kwargsDefs = {
        from: 0, size: 5, fields: [ "name", "description" ]
      };
      kwargs = Object.assign(kwargsDefs, kwargs);

      const url = new URL(ELASTIC_URL + 'film/_search');
      // Elastic docs: 
      // For libraries that don’t accept a request body 
      // for non-POST requests, you can pass the request 
      // body as the source query string parameter instead.
      url.searchParams.set('source', JSON.stringify({
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
      return fetch(url)
        .then(response => {
          if (response.status >= 400) {
              throw new Error("Bad response from server");
          }
          return response.json();
        })
        .then(({ hits }) => {
          const items = hits.hits
            .map(hit => hit.fields)
            .map(film => {
              film.date = film.date && film.date.map(d => new Date(d));
              return film;
            });
          return {
            items,
            total: hits.total
          };
        });
    }

    export default {
      search,
    }

Простейший ReactJS компонент для отображения фильмов:

*src/films-search/films-search.component.jsx*

    :::text
    import React from 'react';
    import elastic from './elastic.service.js';


    class Film extends React.Component {
      render() {
        const film = this.props.film,
              opt = v => v && v.join(' | '),
              date = v => v && v.map(d => d.toLocaleDateString())

        return (
          <div>
            <p>
              <b>Название: </b>{film.name} {' | '}
              <a href={"https://www.kinopoisk.ru/film/" + film.id}>{film.rate}</a>
              {' | '} {date(film.date)}
            </p>
            <p>
              <b>Режиссёр: </b>{opt(film.directed)}
            </p>
            <p>
              <b>Жанр: </b>{opt(film.category)}
            </p>
            <p>
              <b>Актёры: </b>{opt(film.starring)}
            </p>
            <p>
              <b>Описание: </b>{film.description}
            </p>
            <hr/>
          </div>
        );
      }
    }
    Film.propTypes = { 
      film: React.PropTypes.shape({
        id: React.PropTypes.arrayOf(React.PropTypes.number).isRequired,
        name: React.PropTypes.arrayOf(React.PropTypes.string).isRequired,
        rate: React.PropTypes.arrayOf(React.PropTypes.number).isRequired,
        date: React.PropTypes.arrayOf(React.PropTypes.instanceOf(Date)),
        category: React.PropTypes.arrayOf(React.PropTypes.string),
        starring: React.PropTypes.arrayOf(React.PropTypes.string),
        directed: React.PropTypes.arrayOf(React.PropTypes.string),
        description: React.PropTypes.arrayOf(React.PropTypes.string).isRequired,
      }) 
    };

    class FilmsList extends React.Component {

      render() {
        const filmNodes = this.props.films.map(film => (
          <Film film={film} key={film.id} />
        ));
        return (
           <div>
              {filmNodes}
           </div>
        );
      }
    }
    FilmsList.propTypes = {
      films: React.PropTypes.array.isRequired
    };

    export default class extends React.Component {

      constructor(props) {
        super(props);
        this.state = { films: [] };
      }

      componentDidMount() {
        elastic.search().catch(e => alert(e)).then(
          data => this.setState({films: data.items})
        );
      }

      render() {
        return (
           <FilmsList films={this.state.films}/>
        );
      }
    }

**JSX** это HTML подобный синтаксис, компилируемый в JavaScript. Разметка и код находятся в одном файле. Задавать ```propTypes``` необязательно, но весьма полезно - это дополнительная проверка данных на этапе выполнения кода плюс самодокументирующийся код для описания компонентов и их взаимодействия.

Осталось самую малость, чтобы увидеть первые результаты в браузере:

*src/app.jsx*

    :::text
    import React from 'react';
    import FilmsSearch from './films-search/films-search.component.jsx'

    export default class extends React.Component {
       render() {
          return (
             <FilmsSearch/>
          );
       }
    }

*src/index.html*

    :::html
    <!DOCTYPE html>
    <html>
       <head>
          <meta charset="UTF-8">
          <title>ElasticSearch React</title>
       </head>
       <body>
          <div id="app"></div>
          <script src="bundle.js"></script>
       </body>
    </html>

*src/main.js*

    :::js
    import React from 'react';
    import ReactDOM from 'react-dom';
    import App from './app.jsx';

    ReactDOM.render(<App />, document.getElementById('app'));

Результат !

![screenshot]({attach}hello-world-react.png){:style="width:100%; border:1px solid #ddd;"}

Дальше интересней. Расширим Elastic сервис подсказками, агрегацией, подсветкой и.т.д.:

*src/films-search/elastic.service.js*

    :::js
    import fetch from 'isomorphic-fetch';

    const ELASTIC_URL = 'http://localhost:9200/kinopoisk/';

    function search(kwargs) {
      const kwargsDefs = {
        from: 0, size: 5, fields: [ "name", "description" ]
      };
      kwargs = Object.assign(kwargsDefs, kwargs);

      const url = new URL(ELASTIC_URL + 'film/_search');
      url.searchParams.set('source', JSON.stringify({
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
      return fetch(url)
        .then(response => {
          if (response.status >= 400) {
              throw new Error("Bad response from server");
          }
          return response.json();
        })
        .then(({ hits, aggregations }) => {
          const chunk = {
            items: hits.hits
              .map(
                hit => Object.assign(hit.fields, hit.highlight))
              .map(film => {
                film.date = film.date && film.date.map(d => new Date(d));
                return film;
              }),
            total: hits.total
          };
          const aggs = {
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

    function suggest(a, size=10) {
      const url = new URL(ELASTIC_URL + '_suggest');
      url.searchParams.set('source', JSON.stringify({
        "kino" : {
          "text" : a,
          "completion" : {
            "field" : "suggest",
            "size": size
          }
        }
      }));
      return fetch(url)
        .then(response => {
          if (response.status >= 400) {
              throw new Error("Bad response from server");
          }
          return response.json();
        })
        .then(data => {
          const opts = data.kino[0].options;
          return opts.map(opt => opt.text);
        });
    }

    export default {
      search,
      suggest
    }

Реальное React приложение состоит из множества компонентов, которые могут передавать данные как от родителя к дочернему элементу так и наоборот. Например компонент FilmsList получает данные от родителя в ```props.films``` и в свою очередь передаёт свои данные в компонент подсветки Hi: 

*src/app/films-search/films-list/films-list.component.jsx*

    :::text
    import React from 'react';
    import Hi from '../hi/hi.component.jsx';

    class Film extends React.Component {
      render() {
        const film = this.props.film,
              opt = (v, s=' | ') => v && v.join(s),
              date = v => v && v.map(d => d.toLocaleDateString())

        return (
          <div>
            <hr/>
            <p>
              <b>Название: </b><Hi content={film.name} /> {' | '}
              <a href={'https://www.kinopoisk.ru/film/' + film.id}>{film.rate}</a>
              {' | '} {date(film.date)}
            </p>
            <p>
              <b>Режиссёр: </b>{opt(film.directed)}
            </p>
            <p>
              <b>Жанр: </b>{opt(film.category)}
            </p>
            <p>
              <b>Актёры: </b>{opt(film.starring)}
            </p>
            <p>
              <b>Описание: </b><Hi content={opt(film.description, '...')} />
            </p>
          </div>
        );
      }
    }
    Film.propTypes = { 
      film: React.PropTypes.shape({
        id: React.PropTypes.arrayOf(React.PropTypes.number).isRequired,
        name: React.PropTypes.arrayOf(React.PropTypes.string).isRequired,
        rate: React.PropTypes.arrayOf(React.PropTypes.number).isRequired,
        date: React.PropTypes.arrayOf(React.PropTypes.instanceOf(Date)),
        category: React.PropTypes.arrayOf(React.PropTypes.string),
        starring: React.PropTypes.arrayOf(React.PropTypes.string),
        directed: React.PropTypes.arrayOf(React.PropTypes.string),
        description: React.PropTypes.arrayOf(React.PropTypes.string).isRequired,
      }) 
    };

    class FilmsList extends React.Component {

      render() {
        const filmNodes = this.props.films.map(film => (
          <Film film={film} key={film.id} />
        ));
        return (
           <div>
              {filmNodes}
           </div>
        );
      }
    }
    FilmsList.propTypes = {
      films: React.PropTypes.array.isRequired
    };

    export default FilmsList;

Компонент Hi:

*src/app/films-search/hi/hi.component.jsx*

    :::text
    import React from 'react';

    class Hi extends React.Component {

      constructor(props) {
        super(props);
        this.state = { hiHtml: '' };
      }

      updateHiHtml(){
        const {me} = this.refs;
        if (me) {
          const hiHtml = me.innerHTML.replace(
              /\[mazko\.github\.io\](.*?)\[\/mazko\.github\.io\]/g, 
              "<b style=\"color:red;\">$1</b>"
          );
          if (me.innerHTML !== hiHtml) {
            this.setState({hiHtml}); 
          }
        }  
      }

      componentDidUpdate() {
        this.updateHiHtml();
      }

      componentDidMount() {
        this.updateHiHtml();
      }

      componentWillReceiveProps() {
        this.setState({hiHtml: ''});
      }

      render() {
        return (
          this.state.hiHtml 
            ? <span dangerouslySetInnerHTML={{__html: this.state.hiHtml}} />
            : <span ref='me'>{this.props.content}</span>
        );
      }
    }
    Hi.propTypes = {
      content : React.PropTypes.oneOfType([
        React.PropTypes.string,
        React.PropTypes.arrayOf(React.PropTypes.string)
      ]).isRequired
    };

    export default Hi;

Поле ввода поискового запроса в свою очередь уже отсылает данные родителю - событие onQueryChange:

*src/app/films-search/auto-complete/auto-complete.component.jsx*

    :::text
    import React from 'react';
    import elastic from '../elastic.service';
    import styles from './auto-complete.component.css';

    class Autocomplete extends React.Component {

      constructor(props) {
        super(props);
        this.state = { suggestions: [], query: '' };
      }

      handleKeyUp(e) {
        if (e.key === 'Enter') {
          this.props.onQueryChange(e.target.value);
        }
        if (['Enter', 'Escape'].indexOf(e.key) > -1) {
          this.setState({suggestions: []});
        }
      }

      handleChange(e) {
        const query = e.target.value;
        this.setState({query});
        elastic.suggest(query).then( /* TODO: debounce */
          suggestions => this.setState({suggestions})
        );
      }

      handleDocumentClick(e) {
        if (this.refs.menu.contains(e.target)) {
          const query = e.target.dataset['val'];
          this.props.onQueryChange(query);
          this.setState({query});
        } 
        this.setState({suggestions: []});
      }

      componentWillMount() {
        document.addEventListener('click', 
          this.handleDocumentClick.bind(this), false);
      }

      componentWillUnmount() {
        document.removeEventListener('click', 
          this.handleDocumentClick.bind(this), false);
      }

      render() {
        const menu = this.state.suggestions.map(
          v => (
            <li key={v} data-val={v} className={styles.ulli}>{v}</li>
          )
        );
        return (
          <div className={styles.div}>
            <span>
              <input
                type="text" 
                placeholder="пример:космос" 
                autoComplete="off"
                onChange={this.handleChange.bind(this)}
                value={this.state.query}
                onKeyUp={this.handleKeyUp.bind(this)} />
            </span>
            <ul ref='menu'>
              {menu}
            </ul>
          </div>
        );
      }
    }
    Autocomplete.propTypes = {
      onQueryChange : React.PropTypes.func
    };

    export default Autocomplete;

*src/app/films-search/auto-complete/auto-complete.component.css*

    :::css
    .div {
      flex-grow: 1;
    }

    .div input {
      text-align: center;
      flex-grow: 1;
      font-size: inherit;
    }

    .div span {
      display: flex;
      height: 100%;
    }

    .div ul {
      padding: 0px;
      margin: 0px;
      border: solid 1px #f1f1f1;
      position: absolute;
      background: #FFF;
    }

    .div ul li {
      list-style: none;
      padding: 5px;
      margin: 0px;
      color: #7E7E7E;
      cursor: pointer;
    }

    .div ul li:hover {
      background-color: #f1f1f1;
      color: #000;
    }

В компоненте Aggregations присутствуют оба случая:

*src/app/films-search/aggregations/aggregations.component.jsx*

    :::text
    import React from 'react';
    import styles from './aggregations.component.css';

    class AggregationsComponent extends React.Component {

      constructor(props) {
        super(props);
        this.state = {};
      }

      componentWillReceiveProps(nextProps) {
        let {aggs} = nextProps;

        if (!aggs) return;
        // clone
        aggs = Object.assign({}, aggs);
        // Flatten array easier to render
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

        // user friendly empty search results
        const {
          search_star, search_director, search_category,
          search_month, search_year
        } = this.state;

        if (search_star && aggs.stars.length === 0) {
          aggs.stars = [{key: search_star, doc_count: 0}];
        }
        if (search_category && aggs.categories.length === 0) {
          aggs.categories = [{key: search_category, doc_count: 0}];
        }
        if (search_director && aggs.directors.length === 0) {
          aggs.directors = [{key: search_director, doc_count: 0}];
        }
        if (search_month && aggs.years.length === 0) {
          aggs.years = [
            {year: search_year, doc_count: 0},
            {year: search_year, month: search_month, doc_count: 0}
          ];
        } else if (search_year && aggs.years.length === 0) {
          aggs.years = [{year: search_year, doc_count: 0}];
        }

        this.setState({aggs});
      }

      handleStar(e) {
        this.setState({search_star: e.target.value}, this._emit);
      }

      handleDirector(e) {
        this.setState({search_director: e.target.value}, this._emit);
      }

      handleCaterory(e) {
        this.setState({search_category: e.target.value}, this._emit);
      }

      handleYM(e) {
        const idx = e.target.value, {aggs} = this.state;
        if (idx >= 0) {
          this.setState({
              search_year: aggs.years[idx]['year'],
              search_month: aggs.years[idx]['month'],
            }, this._emit);
        } else {
          this.setState({
              search_year: undefined,
              search_month: undefined,
            }, this._emit);
        }
      }

      _emit() {
        this.props.onAggsChange({
          year: this.state.search_year,
          month: this.state.search_month,
          star: this.state.search_star,
          category: this.state.search_category,
          director: this.state.search_director
        });
      }

      render() {
        const {
          aggs, search_star, search_director, search_category,
          search_month, search_year
        } = this.state;

        const ym = aggs && aggs.years.map((v, i) => (
          <option key={i} value={i}>
            {(v.month >= 0 
                ? '-> ' + ("00" + v.month).slice(-2) 
                : v.year) + ' | ' + v.doc_count}
          </option>
          )
        );

        const stars = aggs && aggs.stars.map(v => (
          <option key={v.key} value={v.key}>
            {v.doc_count} | {v.key}
          </option>
          )
        );

        const dirs = aggs && aggs.directors.map(v => (
          <option key={v.key} value={v.key}>
            {v.doc_count} | {v.key}
          </option>
          )
        );

        const cats = aggs && aggs.categories.map(v => (
          <option key={v.key} value={v.key}>
            {v.doc_count} | {v.key}
          </option>
          )
        );

        const search_ym_idx = aggs && aggs.years.findIndex(v => 
          v.month === search_month && v.year === search_year);

        return (
          <span className={styles.span}>
            <select value={search_ym_idx}
                    onChange={this.handleYM.bind(this)}>
              <option value='-1'>&nbsp;</option>
              {ym}
            </select>
            <select value={search_star} 
                    onChange={this.handleStar.bind(this)}>
              <option value=''>&nbsp;</option>
              {stars}
            </select>
            <select value={search_director} 
                    onChange={this.handleDirector.bind(this)}>
              <option value=''>&nbsp;</option>
              {dirs}
            </select>
            <select value={search_category} 
                    onChange={this.handleCaterory.bind(this)}>
              <option value=''>&nbsp;</option>
              {cats}
            </select>
          </span>
        );
      }
    }
    AggregationsComponent.propTypes = {
      onAggsChange : React.PropTypes.func,
      filter: React.PropTypes.shape({
        year: React.PropTypes.number,
        month: React.PropTypes.number,
        star: React.PropTypes.string,
        category: React.PropTypes.string,
        director: React.PropTypes.string
      }) 
    };

    export default AggregationsComponent;

*src/app/films-search/aggregations/aggregations.component.css*

    :::css
    .span {
      display: flex;
    }

    .span select {
      font-size: inherit;
      text-overflow: ellipsis;
    }

    .span select {
      flex-grow: 1;
    }

    .span select:not(:first-of-type) {
      margin-left: 7px;
    }

Последний штрих - связать всё в одном компоненте FilmsSearch:

*src/app/films-search/films-search.component.ts*

    :::text
    import React from 'react';
    import elastic from './elastic.service';
    import FilmsList from './films-list/films-list.component.jsx';
    import Autocomplete from './auto-complete/auto-complete.component.jsx';
    import AggsComponent from './aggregations/aggregations.component.jsx';

    import styles from './films-search.component.css';

    export default class extends React.Component {

      constructor(props) {
        super(props);
        this.state = { 
          films: [],
          films_per_page: 5,
        };
      }

      componentDidMount() {
        this.handleQuery();
      }

      handleQuery(search_query) {
        this.setState(
          {current_page: 1, search_query}, 
          this._search
        );
      }

      handlePerPage(e) {
        this.setState(
          {films_per_page: e.target.value},
          () => this.handleQuery(this.state.search_query)
        );
      }

      handlePrevPage() {
        this.setState(
          {current_page: this.state.current_page -1},
          this._search
        );
      }

      handleNextPage() {
        this.setState(
          {current_page: this.state.current_page +1}, 
          this._search
        );
      }

      handleAggs(search_aggs) {
        this.setState({search_aggs},
          () => this.handleQuery(this.state.search_query));
      }

      _search() {
        const {
          current_page, total_pages, films_per_page,
          search_query, search_aggs
        } = this.state, from = (current_page - 1) * films_per_page;
        this.setState({is_fetching_state: true});
        elastic.search(Object.assign({
          from, size: films_per_page,
          q: search_query
        }, search_aggs)).catch(e => alert(e)).then(
          ({chunk, aggs}) => {
            this.setState({
              aggs,
              is_fetching_state: false,
              films: chunk.items,
              total_pages: Math.ceil(chunk.total / films_per_page)
            })
        }); 
      }

      render() {
        const {
          current_page, total_pages, films_per_page, is_fetching_state
        } = this.state;
        return (
          <div className={styles.div}>
            <div className={styles.row}>
              <Autocomplete onQueryChange={this.handleQuery.bind(this)} />
              <span className={styles.span}>
                <select className={styles.select} 
                        disabled={is_fetching_state}
                        value={films_per_page} 
                        onChange={this.handlePerPage.bind(this)}>
                  { 
                    [3, 5, 10, 25].map(v => 
                    (<option key={v} value={v}>{v}</option>)) 
                  }
                </select>
              </span>

              {
                current_page > 1
                ? <button className={styles.button}
                          disabled={is_fetching_state}
                          onClick={this.handlePrevPage.bind(this)}>
                    {'<'}
                  </button>
                : null
              }
              
              {
                current_page < total_pages
                ? <button className={styles.button} 
                          disabled={is_fetching_state}
                          onClick={this.handleNextPage.bind(this)}>
                    {'>'}
                  </button>
                : null
              }

              <span className={styles.span + ' ' + styles.center}>
                Страница {current_page} из {total_pages}
              </span>

            </div>

            <p>
              <AggsComponent aggs={this.state.aggs} 
                  onAggsChange={this.handleAggs.bind(this)} />
            </p>  

            <FilmsList films={this.state.films} />
          </div>
        );
      }
    }

*src/app/films-search/films-search.component.css*

    :::css
    .div {
      font-size: 18px;
    }

    .row {
      display: flex;
      margin: 15px 0px;
    }

    .select {
      margin-left: 2px;
      font-size: inherit;
      text-overflow: ellipsis;
      flex: 1;
    }

    .button {
      margin-left: 7px;
      align-self: stretch;
      font-size: inherit;
    }

    .span {
      margin-left: 5px;
      display: flex;  
    }

    .center {
      align-items: center;
      justify-content: center; 
    }

Сборка для демо на картинке ```webpack --config webpack.config.prod.js```:

*webpack.config.prod.js*

    :::js
    var dev = require("./webpack.config.js"),
        webpack = require('webpack');

    dev.plugins = dev.plugins || [];

    dev.plugins.push(
      new webpack.DefinePlugin({
        'process.env': {
          'NODE_ENV': JSON.stringify('production')
        }
      })
    );

    dev.plugins.push(
      new webpack.optimize.UglifyJsPlugin({
        compress: {
          warnings: false
        }
      })
    );

    module.exports = dev;