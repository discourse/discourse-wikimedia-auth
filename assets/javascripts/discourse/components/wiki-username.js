import Component from "@ember/component";
import { schedule } from "@ember/runloop";
import { service } from "@ember/service";
import { classNameBindings, tagName } from "@ember-decorators/component";
import $ from "jquery";
import discourseComputed from "discourse/lib/decorators";

@classNameBindings(":wiki-username")
@tagName("h2")
export default class WikiUsername extends Component {
  @service siteSettings;

  didInsertElement() {
    super.didInsertElement(...arguments);
    schedule("afterRender", () => {
      const $el = $(this.element);
      $el.insertAfter(".full-name");
      $(".full-name").toggleClass("add-margin", Boolean(this.user.name));
    });
  }

  @discourseComputed("user.wiki_username")
  wikiUserUrl(wikiUsername) {
    return `${this.siteSettings.wikimedia_auth_site}/wiki/User:${wikiUsername}`;
  }
}
