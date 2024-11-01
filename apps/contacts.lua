local tui = require("touchui")
local container = require("touchui.containers")
local input = require("touchui.input")
local popups = require("touchui.popups")
local list = require("touchui.lists")
local draw = require("draw")

local function paddedWindow(padding)
    padding = padding
    local termw, termh = term.getSize()
    return window.create(term.current(), padding + 1, padding + 1, termw - 2 * padding, termh - 2 * padding)
end

local testWin = window.create(term.current(), 1, 1, term.getSize())

remos.setTitle("Contacts")

local contacts = {}
if fs.exists(".contacts") then
    local file = fs.open(".contacts", "r")
    local contents = file.readAll()
    file.close()
    contacts = textutils.unserialize(contents)
end

local function save()
    local file = fs.open(".contacts", "w")
    file.write(textutils.serialize(contacts))
    file.close()
end

local function editContactMenu(contact, label)
    local rootWin = paddedWindow(2)
    local rootVbox = container.vBox()
    local rootBox = container.framedBox(rootVbox)
    rootBox:setWindow(rootWin)
    local titleText = tui.textWidget(label, "c")
    rootVbox:addWidget(titleText, 1)

    local attributeVbox = container.vBox()


    local name = contact.name
    local nameInput = input.inputWidget("Name", nil, function(value)
        name = value
    end)
    nameInput.value = name
    attributeVbox:addWidget(nameInput)

    local number = contact.number
    local numberInput = input.inputWidget("Number", nil, function(value)
        number = value
    end)
    numberInput.value = number
    attributeVbox:addWidget(numberInput)

    local controlsHBox = container.hBox()

    local action = "cancel"

    controlsHBox:addWidget(input.buttonWidget("Save", function(self)
        contact.name = name
        contact.number = number
        rootBox.exit = true
        action = "save"
    end))

    controlsHBox:addWidget(input.buttonWidget("Cancel", function(self)
        rootBox.exit = true
    end))

    attributeVbox:addWidget(controlsHBox)

    rootVbox:addWidget(attributeVbox)

    tui.run(rootBox, true)
    return action
end

local function contactMenu(contact, index)
    local fileOptions = {
        "Delete",
        "Edit",
    }

    local label = "Contact Options"
    local attributeVbox = container.vBox()

    attributeVbox:addWidget(tui.textWidget(("Name: %s"):format(contact.name), "l"), 2)
    attributeVbox:addWidget(tui.textWidget(("Number: %s"):format(contact.number), "l"), 1)

    local i, item = popups.listPopup(label, fileOptions, 1, function(win, x, y, w, h, item, theme)
        draw.text(x, y, item, win)
    end, attributeVbox)
    if item then
        if item == "Delete" and popups.confirmationPopup(("Delete %s?"):format(contact.name), "Are you sure you want to delete this contact?") then
            table.remove(contacts, index)
            save()
        elseif item == "Edit" then
            editContactMenu(contact, ("Edit Contact"):format(contact.name))
            save()
        end
    end
end

local rootvbox = container.vBox()
rootvbox:setWindow(testWin)

rootvbox:addWidget(input.buttonWidget("Add contact", function(self)
    local contact = {
        name = "New contact",
        number = ""
    }

    local action = editContactMenu(contact, "New Contact")
    if action == "save" then
        table.insert(contacts, contact)
        save()
    end
end), 3)

local titleText = tui.textWidget("", "c")
rootvbox:addWidget(titleText, 1)

local inbox = list.listWidget(contacts, 2,
    function(win, x, y, w, h, item, theme)
        if y % 2 == 1 then
            draw.set_col(theme.inputfg, theme.inputbg, win)
        end

        draw.clear_line(y, win)
        draw.text(x, y, ("%s (%s)"):format(item.name, item.number), win)
        draw.clear_line(y + 1, win)
        draw.text(x, y + 2 - 1, ("\140"):rep(w), win)
        draw.set_col(theme.fg, theme.bg, win)
    end, function(index, item)
        contactMenu(item, index)
    end, nil, nil)

rootvbox:addWidget(inbox)

tui.run(rootvbox)
