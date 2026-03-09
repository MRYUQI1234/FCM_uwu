// interaction.js
console.log("FCM: Interaction script loaded.");

// Main setup function that logic attaches to the viewer
function attachInteractionLogic(modelViewer) {
    if (modelViewer.dataset.hasFCMInteraction) return; // Already attached
    modelViewer.dataset.hasFCMInteraction = "true";

    console.log("FCM: <model-viewer> found and attached!");

    // Track mouse movement to differentiate Click vs Drag
    let startX = 0;
    let startY = 0;
    let isDragging = false;

    // Use Pointer Events (better for model-viewer)
    modelViewer.addEventListener('pointerdown', (event) => {
        startX = event.clientX;
        startY = event.clientY;
        isDragging = false;
    }, true); // Capture phase

    modelViewer.addEventListener('pointerup', (event) => {
        const diffX = Math.abs(event.clientX - startX);
        const diffY = Math.abs(event.clientY - startY);

        // If moved more than 5 pixels, consider it a drag (rotate) -> Do nothing
        if (diffX > 5 || diffY > 5) {
            isDragging = true;
            console.log("FCM: Drag detected, ignoring click.");
            return;
        }

        // Clean Click Detected!

        // 1. EXECUTE OUR LOGIC FIRST
        handleClick(event, modelViewer);

        // 2. STOP PROPAGATION IMMEDIATELY
        event.stopPropagation();
        event.preventDefault();
    }, true); // Capture phase

    // Separate click handler logic
    function handleClick(event, modelViewer) {
        // 1. Capture current camera target BEFORE processing
        const currentTarget = modelViewer.getCameraTarget();

        const material = modelViewer.materialFromPoint(event.clientX, event.clientY);

        if (material != null) {
            console.log("FCM: Material clicked:", material.name);

            // IGNORE if material is hidden (Roof in transparency mode)
            if (material.isHidden) {
                console.log("FCM: Clicked hidden material, ignoring.");
                return;
            }

            // Store original color if not already stored
            if (!material.originalColor) {
                material.originalColor = [...material.pbrMetallicRoughness.baseColorFactor];
            }

            // Toggle Logic
            if (material.isHighlighted) {
                // Revert to original
                material.pbrMetallicRoughness.setBaseColorFactor(material.originalColor);
                material.isHighlighted = false;
                console.log("FCM: Un-highlighted");
            } else {
                // Highlight Blue
                material.pbrMetallicRoughness.setBaseColorFactor([0.2, 0.4, 1.0, 1.0]);
                material.isHighlighted = true;
                console.log("FCM: Highlighted");
            }
        } else {
            console.log("FCM: Clicked on background (no material)");
        }

        // 2. FORCE Restore Camera Target immediately (cancels out the auto-center)
        setTimeout(() => {
            modelViewer.cameraTarget = currentTarget.toString();
        }, 0);

        // 3. Notify Flutter
        if (window.onObjectClicked && material != null) {
            window.onObjectClicked(material.name);
        } else {
            console.log("FCM: onObjectClicked ignored (no listener or no material)");
        }
    }
}

// Function to find the viewer
function checkAndSetup() {
    const modelViewer = document.querySelector('model-viewer');
    if (modelViewer) {
        attachInteractionLogic(modelViewer);
    }
}

// Initialize Observer to watch for <model-viewer> appearing in DOM
const observer = new MutationObserver((mutations) => {
    checkAndSetup();
});

// Start observing the document body for added nodes
window.addEventListener('load', () => {
    console.log("FCM: Starting DOM Observer...");
    checkAndSetup(); // Check once immediately
    observer.observe(document.body, { childList: true, subtree: true });
});

// Exposed function for Flutter to call
window.toggleRoof = function () {
    const modelViewer = document.querySelector('model-viewer');
    if (!modelViewer || !modelViewer.model) return;

    const materials = modelViewer.model.materials;
    let foundRoof = false;

    // Target specific roof materials based on user feedback
    const roofKeywords = ['roof', 'gaf_country_mansion', 'material_0'];

    for (const material of materials) {
        const matName = material.name.toLowerCase();
        // Check if material name matches any of our keywords
        if (roofKeywords.some(keyword => matName.includes(keyword))) {
            foundRoof = true;

            // Store original alpha if not stored
            if (material.originalAlpha === undefined) {
                material.originalAlpha = material.pbrMetallicRoughness.baseColorFactor[3]; // get alpha
            }

            const currentAlpha = material.pbrMetallicRoughness.baseColorFactor[3];

            // Toggle Logic
            if (currentAlpha > 0.1) {
                // HIDE
                const color = material.pbrMetallicRoughness.baseColorFactor;
                color[3] = 0.0; // Transparent
                material.pbrMetallicRoughness.setBaseColorFactor(color);

                material.setAlphaMode('BLEND');
                material.isHidden = true; // Mark as hidden for click logic
                console.log("FCM: Roof Hidden (" + material.name + ")");
            } else {
                // SHOW
                const color = material.pbrMetallicRoughness.baseColorFactor;
                color[3] = material.originalAlpha || 1.0;
                material.pbrMetallicRoughness.setBaseColorFactor(color);

                material.isHidden = false; // Mark as visible
                console.log("FCM: Roof Visible (" + material.name + ")");
            }
        }
    }

    if (!foundRoof) {
        console.log("FCM: Still no roof found. Check names.");
        // alert removed to be less annoying, rely on console
    }
};

// Exposed function to Clear Highlights
window.clearHighlight = function () {
    const modelViewer = document.querySelector('model-viewer');
    if (!modelViewer || !modelViewer.model) return;

    console.log("FCM: Clearing all highlights...");

    for (const material of modelViewer.model.materials) {
        if (material.isHighlighted) {
            if (material.originalColor) {
                material.pbrMetallicRoughness.setBaseColorFactor(material.originalColor);
            }
            material.isHighlighted = false;
        }
    }
};

// Exposed function to Toggle Interactivity (called by Flutter when dialog opens/closes)
window.toggleInteractable = function (isInteractable) {
    const modelViewer = document.querySelector('model-viewer');
    if (!modelViewer) return;

    if (isInteractable) {
        modelViewer.style.pointerEvents = 'auto';
        console.log("FCM: Model interaction ENABLED");
    } else {
        modelViewer.style.pointerEvents = 'none';
        console.log("FCM: Model interaction DISABLED");
    }
};

// Initialization complete - all interactions handled by observer above
