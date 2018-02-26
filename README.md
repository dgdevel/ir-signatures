ir-signatures
=============

It's configured with 3 files:

- `credentials.yaml` contains username and password for the iracing service
- `drivers.yaml` list all the drivers, defined by the name displayed, the customer id for iracing service, the image template and the text to be displayed
- `templates.yaml` bind the images to the text overlay, defining font and colors, position

The `:text` variable in drivers.yaml is an ERB string, with the following available variables: `name`, `{oval,road,dirtoval,dirtroad}Irating`, `{oval,road,dirtoval,dirtroad}License`

Examples are provided in the yaml files.
