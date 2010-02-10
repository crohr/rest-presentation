#!/bin/sh
# simple GET
curl -i http://localhost:4567/authors/crohr/papers

# follow the link
curl -i http://localhost:4567/papers/some-well-chosen-title -H'Accept: application/json'
curl -i http://localhost:4567/papers/some-well-chosen-title -H'Accept: text/html'
open http://localhost:4567/papers/some-well-chosen-title

# conditional GET
curl -i http://localhost:4567/papers/some-well-chosen-title -H'Accept: application/json' -H'If-None-Match: "d6d442ce1792441d05a019af700943e3e783706a"'

# update conflict
curl -i -X PUT http://localhost:4567/papers/some-well-chosen-title -H'Accept: application/json' -H'Content-Type: application/json' -d '{"title":"Some Well Chosen Title", "tags": ["rest", "http"], "content": "# Title1\n#Title2", "authors": ["crohr", "gdupond"]}'

# update OK
curl -i -X PUT http://localhost:4567/papers/some-well-chosen-title -H'Accept: application/json' -H'Content-Type: application/json' -d '{"title":"Some Well Chosen Title", "tags": ["rest", "http"], "content": "# Title1\n#Title2\n", "authors": ["crohr", "gdupond"], "revision": 1}'

# new paper
curl -i -X POST 'http://localhost:4567/papers' -H'Accept: application/json' -H'Content-Type: application/json' -d '{"title":"Another Well-Chosen Title", "authors":["crohr"], "content":"# Title\nHello\n"}'

# check existence
curl -i http://localhost:4567/papers/1-another-well-chosen-title  -H'Accept: text/plain'

# delete paper
curl -X DELETE -i http://localhost:4567/papers/1-another-well-chosen-title

# check
curl -i http://localhost:4567/authors/crohr/papers
