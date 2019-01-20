# Changelog

## v?.?.? (????-??-??)
### Added
* position preference and ordering priority for both menus and menu items
* menu merging: Menus and containing submenus with the same name are merged together
    * merging only takes place when there is a filetype collision, i.e. the items being merged have at least one filetype in common. Otherwise the items are left intact.
    * An error is thrown if two items with the same name are to be merged but contain different commands.
* displaying items according to the specified position preference and ordering priority:
    * entries with the same position are ordered by their priority and displayed subsequently
    * subsequent entries may not meet their specified position preference in case more entries were assigned to previous positions than fit before reaching subsequent entrys' positions
    * in case positions are left blank empty entries are displayed
* Venu function `venu#unregisterAll` to unregister all menus.
### Changed
* Remove obscure menu property names beginning with "_"
* Script internal functions are not exposed
### Fixed
* Fix incorrect function call

## v0.0.3 (2018-12-09)
### Fixed
* Read the correct version file

## v0.0.2 (2018-12-09)
### Changed
* Renamed `venu#addOption` to `venu#addItem`
### Added
* Version displayed in Venu title
* CHANGELOG.md to track changes

## v0.0.1 (2018-12-08)
