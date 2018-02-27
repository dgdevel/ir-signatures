ir-signatures
=============

It's configured with 3 files:

- `credentials.yaml` contains username and password for the iracing service
- `drivers.yaml` list all the drivers, defined by the name displayed, the customer id for iracing service, the image template and the text to be displayed
- `templates.yaml` bind the images to the text overlay, defining font and colors, position

The `:text` variable in drivers.yaml is an ERB string, that can utilize a `proxy` object to get data about: `proxy.name` is the driver name (or nickname), `proxy.irating(catId)` is the driver irating, `proxy.license_class(catId)` is the driver license class, `proxy.wins(category)` is the number of wins in the category and `proxy.starts(category)` is the number of starts in the category.

`category` is one of `[Oval, Road, Dirt Oval, Dirt Road]`, `catId` is `[1,2,3,4]` base on the `category`.

Examples are provided in the yaml files.
