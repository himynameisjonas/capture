import Route from '@ember/routing/route';
import { set } from '@ember/object';

export default Route.extend({
  model(){
    return this.store.findAll('request');
  },
  setupController(controller, model) {
    this._super(controller, model);
    var serverSentEvent = new EventSource('/api/requests');
    serverSentEvent.onmessage = (e) => {
      let json = JSON.parse(e.data);
      this.store.pushPayload(json);
      set(controller, 'model', this.store.peekAll('request'))
    }
  },

});
