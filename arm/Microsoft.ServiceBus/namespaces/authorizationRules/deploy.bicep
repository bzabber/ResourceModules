@description('Required. Name of the parent Service Bus Namespace for the Service Bus Queue.')
@minLength(6)
@maxLength(50)
param namespaceName string

@description('Required. The name of the authorization rule')
param name string

@description('Optional. The rights associated with the rule.')
@allowed([
  'Listen'
  'Manage'
  'Send'
])
param rights array = []

@description('Optional. Customer Usage Attribution id (GUID). This GUID must be previously registered')
param cuaId string = ''

module pid_cuaId '.bicep/nested_cuaId.bicep' = if (!empty(cuaId)) {
  name: 'pid-${cuaId}'
  params: {}
}

resource namespace 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' existing = {
  name: namespaceName
}

resource authorizationRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2017-04-01' = {
  name: name
  parent: namespace
  properties: {
    rights: rights
  }
}

@description('The name of the authorization rule.')
output authorizationRuleName string = authorizationRule.name

@description('The Resource ID of the authorization rule.')
output authorizationRuleResourceId string = authorizationRule.id

@description('The name of the Resource Group the authorization rule was created in.')
output authorizationRuleResourceGroup string = resourceGroup().name
