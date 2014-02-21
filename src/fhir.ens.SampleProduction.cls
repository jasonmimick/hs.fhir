Class fhir.ens.SampleProduction Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="fhir.ens.SampleProduction" TestingEnabled="true" LogGeneralTraceEvents="true">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
 <Item Name="fhir.ens.RestService" Category="" ClassName="fhir.ens.RestService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Adapter" Name="Port">57781</Setting>
    <Setting Target="Host" Name="ArchiveIO">1</Setting>
  </Item>
</Production>
}

}

