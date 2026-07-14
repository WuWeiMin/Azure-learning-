GET [组织URL]/api/data/v9.2/EntityDefinitions?$select=LogicalName&$expand=Attributes($select=LogicalName;$filter=LogicalName eq 'yourfieldname')
