import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "wikimedia",
  initialize() {
    withPluginApi("0.8.23", (api) => {
      api.modifyClass(
        "controller:preferences/account",
        (Superclass) =>
          class extends Superclass {
            get canUpdateAssociatedAccounts() {
              return false;
            }
          }
      );
    });
  },
};
