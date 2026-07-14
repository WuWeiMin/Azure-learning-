GET [组织URL]/api/data/v9.2/EntityDefinitions?$select=LogicalName&$expand=Attributes($select=LogicalName;$filter=LogicalName eq 'yourfieldname')


fetch("/api/data/v9.2/EntityDefinitions?$select=LogicalName&$expand=Attributes($select=LogicalName;$filter=LogicalName eq 'aia_utilizationbalance')")
  .then(r => r.json())
  .then(d => {
    const hits = d.value.filter(e => e.Attributes.length > 0).map(e => e.LogicalName);
    console.log(`共 ${hits.length} 个表:`, hits);
  });
