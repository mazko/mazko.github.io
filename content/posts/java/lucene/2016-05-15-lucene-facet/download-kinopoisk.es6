#!/usr/bin/env node

// npm i request cheerio charset iconv-lite fs-extra

// ./crawl/download-kinopoisk.es6 && \
// echo '[' > Top250.json && \
// for f in ./corpus/*; do cat "${f}" >> Top250.json && echo ',' >> Top250.json; done && \
// sed -i '$ d' Top250.json && \
// echo ']' >> Top250.json

const request = require("request")
const cheerio = require("cheerio")
const charset = require("charset")
const iconv   = require("iconv-lite")
const fs      = require("fs-extra")
const url     = require("url")
const assert  = require('assert')


function kinopoisk(to) {
    return new Promise(function(resolve, reject) {
        const options = {
            url: url.resolve('http://www.kinopoisk.ru', to),
            Host: "www.kinopoisk.ru",
            encoding: null, // If null, the body is returned as a Buffer
            timeout: 15000,
            followRedirect: false,
            headers: {
                // http://www.useragentstring.com/pages/Browserlist/
                'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0)',
                'Accept':"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
            }
        }

        request(options, function(error, response, body) {
            if (error) {
                reject(error)
            } else if (response.statusCode !== 200) {
                reject('Bad statusCode: ' + response.statusCode)
            }
            else if(options.url !== response.request.uri.href) {
                // http://stackoverflow.com/q/16687618
                reject(`Unexpected redirect detected ?! code ${response.statusCode}, 
                    diff ${[options.url, response.request.uri.href]}`)
            }
            else {
                const enc = charset(response.headers, body)
                const $ = cheerio.load(iconv.decode(body, enc))
                resolve($)
            }
        })
    })
}

function kp_robust(to) {
    const kp = (to) => new Promise((resolve, reject) => 
        setTimeout(resolve, 4444)).then(() => kinopoisk(to))
    return Array(5).fill().reduce( 
        (prev, curr, index) => 
            prev.catch( (err) => {
                console.log('Retry: ' + index + ', ' + err)
                return kp(to)
            }), 
        kp(to)
    )
}

function kp_page(page)  {
    console.log(`------ Page: ${page} ------`)
    return kp_robust(`/top/navigator/m_act[rating]/4:/order/rating/page/${page}/`)
        .then(($) => $('div#itemList div[id^="tr_"]').map((i, el) => $('div.info div.name a', el).attr('href')).get())
        .then((urls) => 
            urls.reduce((prev, curr, index) => prev.then(() => kp_robust(`/film/${parseInt(curr.match(/(\d+)\/$/)[1])}/`)
                .then(($) => {
                    const id = parseInt(curr.match(/(\d+)\/$/)[1])
                    assert(id, `id can't be empty, -> ${id}`)
                    const name = $('div#headerFilm h1').text().trim()

                    if (!name) {
                        console.log('Skipping INVALID: ', id, name)
                        return;
                    }

                    console.log(id, name)

                    const rate = $('div#block_rating a span.rating_ball').text().trim()
                    assert(rate, `id can't be empty, -> ${rate}`)

                    const description = $('td.news div.brand_words').text().trim()
                    const actors = $('div#actorList ul li').map((i, el) => $(el).text().trim()).get()
                    const opts = $('div#infoTable table.info tr').map(
                        (i, el) => {
                            const a = $('td', el).map((i, el) => $(el).text().trim()).get()
                            return {k: a[0], v: a[1]}
                        }
                    ).get()

                    // console.log(opts)

                    var date = opts.find((v) => v.k === 'премьера (мир)')
                    if (date) {
                        const table = ['января','февраля','марта','апреля',
                                    'мая', 'июня','июля','августа','сентября',
                                    'октября','ноября','декабря']
                        date = date.v.split(',')[0].split(/\s+/)
                        if (table.indexOf(date[1]) === -1) {
                            throw 'Hey, Month !' + date[1]
                        }
                        date = new Date(
                            date[2],                // year
                            table.indexOf(date[1]), // month начинается с 0 для января и кончается 11 для декабря.  
                            date[0])                // day
                    } else {
                        date = new Date(opts.find((v) => v.k === 'год').v)
                    }

                    const category = opts.find((v) => v.k === 'жанр')
                    const country = opts.find((v) => v.k === 'страна')
                    const slogan = opts.find((v) => v.k === 'слоган')
                    const producer = opts.find((v) => v.k === 'режиссер')
                    const composer = opts.find((v) => v.k === 'композитор')

                    const splitHlpr = (s) => s && (!s.v || s.v === '-' ? [] : s.v.split(', ...')[0].split(', '))

                    fs.outputJsonSync(`./corpus/p${page}i${index}`, {
                        id,
                        name,
                        description, 
                        date,
                        rate,
                        starring: actors.indexOf('...') === -1 ? actors : actors.slice(0, actors.indexOf('...')),
                        category: splitHlpr(category),
                        country: splitHlpr(country),
                        slogan: slogan && (slogan.v === '-' ? null : slogan.v),
                        directed: splitHlpr(producer),
                        composer: splitHlpr(composer)
                    })
                })
            ), Promise.resolve())
        )
}

Array(300).fill().reduce(
        (prev, curr, index) => 
            prev.then( () => kp_page(index + 1)), 
        Promise.resolve()
)
.then( () => console.log('done') )
.catch( (err) => console.error(err) )