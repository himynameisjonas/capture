import DS from 'ember-data';

export default DS.Model.extend({
  headers: DS.attr(),
  body: DS.attr('string'),
  method: DS.attr('string'),
  path: DS.attr('string')
});
