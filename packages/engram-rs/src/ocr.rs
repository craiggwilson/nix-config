use anyhow::{anyhow, Context, Result};
use ocrs::{ImageSource, OcrEngine, OcrEngineParams};
use rten::Model;
use std::path::Path;
use std::sync::OnceLock;

static DETECTION_BYTES: &[u8] =
    include_bytes!(concat!(env!("OUT_DIR"), "/text-detection.rten"));
static RECOGNITION_BYTES: &[u8] =
    include_bytes!(concat!(env!("OUT_DIR"), "/text-recognition.rten"));

static ENGINE: OnceLock<OcrEngine> = OnceLock::new();

/// Initialise the OCR engine from the embedded model files.
///
/// Must be called once at startup before any call to [`extract_text`].
/// Subsequent calls are no-ops.
pub fn init() -> Result<()> {
    if ENGINE.get().is_some() {
        return Ok(());
    }

    let detection = Model::load_static_slice(DETECTION_BYTES)
        .map_err(|e| anyhow!("failed to load embedded OCR detection model: {e}"))?;
    let recognition = Model::load_static_slice(RECOGNITION_BYTES)
        .map_err(|e| anyhow!("failed to load embedded OCR recognition model: {e}"))?;

    let engine = OcrEngine::new(OcrEngineParams {
        detection_model: Some(detection),
        recognition_model: Some(recognition),
        ..Default::default()
    })
    .context("failed to create OCR engine")?;

    let _ = ENGINE.set(engine);
    Ok(())
}

/// Extract text from an image file using the embedded OCR engine.
///
/// Returns an empty string when no text is detected. The engine must be
/// initialised via [`init`] before the first call.
pub fn extract_text(path: &Path) -> Result<String> {
    let engine = ENGINE
        .get()
        .ok_or_else(|| anyhow!("OCR engine not initialised — call ocr::init first"))?;

    let img = image::open(path)
        .with_context(|| format!("failed to open image {}", path.display()))?
        .into_rgb8();

    let source = ImageSource::from_bytes(img.as_raw(), img.dimensions())
        .map_err(|e| anyhow!("failed to prepare image source: {e}"))?;

    let input = engine
        .prepare_input(source)
        .context("failed to prepare OCR input")?;

    engine.get_text(&input).context("OCR inference failed")
}
