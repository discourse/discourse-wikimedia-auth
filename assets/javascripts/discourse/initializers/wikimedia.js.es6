import { withPluginApi } from "discourse/lib/plugin-api";
import discourseComputed from "discourse-common/utils/decorators";

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
