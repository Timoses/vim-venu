# V̂enu developer documentation

## Structure of a menu dictionary
* **`name`** _(string)_: Name of the menu.
* **`pos_pref`** _(number)_: Positional preference. Menus/Items with a higher 'priority' win. Losers are positioned after winner. Position preference of '0' means no preference.
* **`priority`** _(number)_: Order and positional priority. Lower numbers have higher priority. Priority of '0' means no priority.
* **`filetypes`** _([string, string, ...])_: Filetypes that this menu will be displayed for.
* **`items`** _([item, item, ...])_: Entries that are displayed for the menu. Each `item` has the following structure:
    * **`name`** _(string)_: Name of the entry
    * **`cmd`** _(string | funcref| menu)_: Command to be executed or menu to be displayed when this entry is selected.
    * **`pos_pref`** _(number)_: Same as `pos_pref` for `menu`.
    * **`priority`** _(number)_: Same as `priority` for `menu`.
    * **`filetypes`** _([string, string, ...])_: Filetypes that this item will be displayed for.


## Callbacks

V̂enu allows its functionality to be customized via callbacks. Exposed callbacks are described below.

* **`g:venu_print_callback`**: Called when `venu#print` is executed.

    * **Parameters**:
        * `name`: Name of the menu
        * `itemsOrMenus`: An array of `item`s or `menu`s to be displayed to the user.


* **`g:venu_format_entry_callback`**: Called for each item to be printed.

    This is called by the default `venu_print_callback` and allows customizing the appearance of each printed row/item in the menu. A customized `venu_print_callback` is not required to call this callback function. In that case, this callback is ignored.

    * **Parameters**:
        * `rowNum`: Number of the row in the menu (i.e. the item's position in the menu)
        * `entry`: `item` or `menu` to be printed.

    * **Return**: Must return the string of the formatted entry.


* **`g:venu_select_callback`**: Called to retrieve the user's selection.

    This is called after the menu has been printed. V̂enu expects it to return an item from `choices` which is either a `menu` or an `item`.

    * **Parameters**:
        * `choices`: Array of choices. Equals the `itemsOrMenus` passed to `g:venu_print_callback`.

    * **Return**: Must return an element from the choices array.

