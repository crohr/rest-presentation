
<!-- putting some comments here
this needs a lot more work :-) but is already more powerful than showoff
Needs to set and use more of the meta-declarations such as {:ruby}, {:incremental}, etc.
-->

<!-- slide cover title centered -->
# Architectures Orientées Services

## Styles, Technologies et Applications

Cyril Rohr (IRISA - Equipe Myriads)
Feb 4, 2010

<!-- slide title -->
# Programme
* Services **Web** ?
* Styles: RPC vs Resource-Oriented
* REST
* Real-World example
{:class="incremental"}

<!-- 
  Concepts (intro, avantages, contraintes)
* Mise en oeuvre (client side, server side, tools)
* Aspects non fonctionnels 
-->

<!-- slide title incremental -->
# Services **Web** ?

*Service* : definition

* exposer des fonctionnalités/ressources via le réseau
* interopérabilité (théoriquement)
* réutilisation/composition pour parvenir à 
* distribution (géographique, fonctionnelle)
* maintenabilité
* whatever
{:class="incremental"}

<!-- slide title -->
# Client Side Code

* Ruby

        require 'restclient'
        RestClient.get "https://api.grid5000.fr/sid/grid5000", :user => "crohr", :password => "whatever"
    {:class="brush: ruby"}
* cURL
        
        $ curl -X GET -kni https://api.grid5000.fr/sid/grid5000
    {:class="brush: bash"}
    
        HTTP/1.1 200 OK
        Date: Fri, 29 Jan 2010 12:12:14 GMT
        ETag: "ca5998adb91af61b9f9c57f2a26f71edebea5ffc"
        Allow: GET
        Cache-Control: public, must-revalidate
        Last-Modified: Mon, 25 Jan 2010 15:31:30 GMT
        Content-Length: 998
        Status: 200
        Content-Type: application/vnd.fr.grid5000.api.grid+json;level=1
        Age: 15023
        X-Cache: HIT from api-proxy.rennes.grid5000.fr

        {
          "uid": "grid5000",
          "type": "grid",
          "version": "1cd3a84ff0c25d269cb24ac294e29b0fe8c111c5",
          "links": [
            {
              "href": "/sid/grid5000/versions/1cd3a84ff0c25d269cb24ac294e29b0fe8c111c5",
              "title": "version",
              "rel": "member",
              "type": "application/vnd.fr.grid5000.api.Version+json;level=1"
            },
            {
              "href": "/sid/grid5000/versions",
              "title": "versions",
              "rel": "collection",
              "type": "application/vnd.fr.grid5000.api.Collection+json;level=1"
            },
            {
              "href": "/sid/grid5000",
              "rel": "self",
              "type": "application/vnd.fr.grid5000.api.Grid+json;level=1"
            },
            {
              "href": "/sid/grid5000/environments",
              "title": "environments",
              "rel": "collection",
              "type": "application/vnd.fr.grid5000.api.Collection+json;level=1"
            },
            {
              "href": "/sid/grid5000/sites",
              "title": "sites",
              "rel": "collection",
              "type": "application/vnd.fr.grid5000.api.Collection+json;level=1"
            }
          ]
        }
    {:class="brush: js; collapse: true; highlight: [1,3,4,5,6,7,8,9,10,11,17,42]"}

<!-- slide title -->
# Server Side Code

<!-- slide title -->
# Démo
![Grid5000][grid5000_img]


[grid5000_img]: images/grid5000.png