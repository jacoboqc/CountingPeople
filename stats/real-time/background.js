Shiny.addCustomMessageHandler("shiny_message", function(message) {
    alert(JSON.stringify(message));
});