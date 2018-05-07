import Controller from '@ember/controller';
import { sort } from '@ember/object/computed';

export default Controller.extend({
  requestSorting: Object.freeze(['receivedAt:desc']),
  sortedRequests: sort('model', 'requestSorting'),
});
