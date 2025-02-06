import discourseComputed from "discourse/lib/decorators";
import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "wikimedia",
  initialize() {
    withPluginApi("0.8.23", (api) => {
      api.modifyClass("controller:preferences/account", {
        pluginId: "discourse-wikimedia-auth",

        @discourseComputed
        canUpdateAssociatedAccounts() {
          return false;
        },
      });
    });
  },
};
