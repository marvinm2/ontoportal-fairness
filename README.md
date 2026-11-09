# ontoportal-fairness

Container image for [O'FAIRe](https://github.com/agroportal/fairness), the FAIRness
assessment service that the OntoPortal UI uses to show FAIR scores for ontologies.
Upstream does not publish an image. This repository builds one from a pinned
upstream commit and publishes it to `ghcr.io/marvinm2/ontoportal-fairness`.

## Image

O'FAIRe is built with Maven and deployed as the ROOT webapp of Tomcat 9. Tomcat 10
and later do not work, because the servlet uses `javax.servlet`.

The upstream commit is set by the `FAIRNESS_REF` build argument in the `Dockerfile`.
The image records it in `/usr/local/tomcat/webapps/ROOT/FAIRNESS_COMMIT`.

## Configuration

At startup the entrypoint writes the portal configuration from these environment
variables:

| Variable | Meaning |
|---|---|
| `PORTAL_URL` | REST API of the OntoPortal instance (required) |
| `PORTAL_APIKEY` / `PORTAL_APIKEY_FILE` | apikey for reading the API |
| `PORTAL_ADMIN_APIKEY` / `PORTAL_ADMIN_APIKEY_FILE` | optional admin key, so private ontologies are assessed too |
| `SERVER_DEFAULT_PORTAL` | portal name, default `ontoportal` |
| `CACHE_ENABLED` | `true`: answer from the cache file (default) |
| `CACHE_FILE_PATH` | cache location, default `/data/fairness/save.json` |

The `_FILE` variants read the value from a file, for example a Docker secret.

## Score cache

With `CACHE_ENABLED=true` the web service answers only from the cache. To build
the cache, run the image with the command `fairness-cache` and the same
environment. Run it after loading ontologies, and on a schedule after that. An
ontology added since the last run has no score.

```bash
docker run --rm -e PORTAL_URL=... -e PORTAL_APIKEY_FILE=... \
  -v cache:/data/fairness ghcr.io/marvinm2/ontoportal-fairness:<tag> fairness-cache
```

## Usage

```
GET /?ontologies=STY            score of one ontology
GET /?ontologies=STY,AGRO&combined
```

## Releases

Every push to `main` publishes `main` and `sha-<short>` tags. A `v*` git tag
publishes the matching version tag.

## License

MIT for the files in this repository. O'FAIRe itself is MIT licensed
(LIRMM, see the upstream repository).
