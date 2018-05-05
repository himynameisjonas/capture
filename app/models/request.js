import DS from 'ember-data';

export default DS.Model.extend({
  body: DS.attr('string'),
  headers: DS.attr(),
  method: DS.attr('string'),
  path: DS.attr('string'),
  receivedAt: DS.attr('date'),
});
