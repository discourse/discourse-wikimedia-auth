import Component from "@ember/component";
import { schedule } from "@ember/runloop";
import { service } from "@ember/service";
import $ from "jquery";
import discourseComputed from "discourse-common/utils/decorators";

export default Component.extend({
  siteSettings: service(),

  classNameBindings: [":wiki-username"],
  tagName: "h2",

  didInsertElement() {
    this._super(...arguments);
    schedule("afterRender", () => {
      const $el = $(this.element);
      $el.insertAfter(".full-name");
      $(".full-name").toggleClass("add-margin", Boolean(this.user.name));
    });
  },

  @discourseComputed("user.wiki_username")
  wikiUserUrl(wikiUsername) {
    return `${this.siteSettings.wikimedia_auth_site}/wiki/User:${wikiUsername}`;
  },
});
