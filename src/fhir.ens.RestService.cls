Class fhir.ens.RestService extends fhir.ens.RestServiceBase
{

ClassMethod hello(name) As %Status
{
	do %output.WriteLine( "Hello "_name)
	return $$$OK
}

XData UrlMap
{
<Routes>
	<Route Url="/hello/:name" Method="GET" Call="hello" />

	<Route Url="/:type/:id" Method="GET" Call="read" />
	<Route Url="/:type/:id/_history/:version" Method="GET" Call="vread" />
	
	</Routes>
}

}
