```
<Resource name="jdbc/tnprcDataSource" auth="Container"
        type="javax.sql.DataSource"
        username="labkey"
        password="password"
        driverClassName="net.sourceforge.jtds.jdbc.Driver"
        url="jdbc:jtds:sqlserver://tsprlsqlc1d01.tulane.local:1433/prc"
        maxAcive="20"
        maxTotal="20"
        maxIdle="10"
        accessToUnderlyingConnectionAllowed="true"
        validationQuery="SELECT 1"
        />
```