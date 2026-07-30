let base = null;
let eliminated = false;
let signalHint = false;
let signalSent = false;
let secondsLeft = null;
let respawnLines = null;

function reset() {
    base = null;
    eliminated = false;
    signalHint = false;
    signalSent = false;
    secondsLeft = null;
    respawnLines = null;
}

function render() {
    const screen = document.getElementById("screen");

    if (!base) {
        screen.classList.remove("visible");
        return;
    }

    document.getElementById("status").textContent = base;

    const showCountdown = secondsLeft !== null;
    document.getElementById("countdown").classList.toggle("visible", showCountdown);
    if (showCountdown) {
        document.getElementById("timer").textContent = `${secondsLeft}`;
    }

    const lines = [];

    if (signalSent) {
        lines.push("Distress signal sent - waiting for help");
    } else if (signalHint) {
        lines.push("Press G to send a distress signal");
    }

    if (respawnLines) {
        lines.push(...respawnLines);
    }

    document.getElementById("lines").textContent = lines.join("\n");
    screen.classList.toggle("eliminated", eliminated);
    screen.classList.add("visible");
}

window.addEventListener("message", function (event) {
    const item = event.data;

    if (item.type === "dead") {
        eliminated = item.state === "eliminated";
        base = eliminated ? "You are dead" : "You are injured";
    } else if (item.type === "knocked_out") {
        base = "You've been knocked out unconscious";
    } else if (item.type === "signal_hint") {
        signalHint = true;
    } else if (item.type === "signal_sent") {
        signalSent = true;
    } else if (item.type === "timer") {
        secondsLeft = item.time;
    } else if (item.type === "respawn_ready") {
        secondsLeft = null;
        respawnLines = [
            `Press ${item.keybind} to respawn - $${item.cost} and you lose your belongings`,
            "Wait for EMS to keep your belongings"
        ];
    } else if (item.type === "ambulance_reset") {
        reset();
    }

    render();
});
