# SQL Developer Integration

Please install first the [oddgen](https://www.oddgen.org/) extension. Our wrapper package is autodiscovered by this extension.

![SQL Developer Integration](images/sql-developer-integration.png)


## Recommended Fastest Way To Your API's

1. Check naming conflicts in your schema before the first API compilation
  - `SELECT * FROM TABLE(om_tapigen.view_naming_conflicts);`
1. Use SQL Developer for the first API creation (you can create API's for multiple tables at once - see screenshot above: emp and dept)
1. Inspect and run the generated code as a script, then save it to your version control system for the deployment
1. View the state of all existing API's
  - `SELECT * FROM TABLE(om_tapigen.view_existing_apis);`
1. On model changes recreate all existing API's with the original parameters
  - `BEGIN om_tapigen.recreate_existing_apis; END;`