# Rekognition Demos

Three sample projects for Amazon Rekognition:

- **LabelDetectionDemo** — `DetectLabels` to identify objects and concepts within an image
- **CustomLabelDetectionDemo** — `DetectCustomLabels` to identify objects using a custom-trained model
- **ContentModerationDemo** — `DetectModerationLabels` to detect potentially unsuitable content

All three share the same pattern: load an image, call the relevant Rekognition
method, and visualise the results with bounding box overlays.

```pascal
LClient := TRekognitionClient.Create;
LResponse := LClient.DetectLabels(TRekognitionImage.FromFile('photo.jpg'));
if LResponse.IsSuccessful then
  for var LLabel in LResponse.Labels do
    WriteLn(Format('%s (%.1f%%)', [LLabel.Name, LLabel.Confidence.Value]));
```

## Label Detection

![Rekognition Demo application detecting labels in an image.](LabelDetection.png)

### Running the label detection sample

1. Open "Rekognition Demos.groupproj" in Delphi or RAD Studio.
2. Activate the LabelDetectionDemo.exe project.
3. Select "Run \> Run" from the menu or press F9.
4. Click the "Open Image..." button and choose an image file.
5. Click "Detect Labels".
6. Once the list of detected labels is populated on the left, you can select an
   item to highlight on the image. Note that some items listed won't have
   instances within the image as they are general scene information.

## Custom Label Detection

![Rekognition Demo application detecting custom labels in an image.](CustomLabelDetection.png)

### Running the custom label detection sample

> **Note:** You will need a pre-trained Amazon Rekognition Custom Labels project
> running in your account.

1. Open "Rekognition Demos.groupproj" in Delphi or RAD Studio.
2. Activate the CustomLabelDetectionDemo.exe project.
3. Select "Run \> Run" from the menu or press F9.
4. Select a model from the list of running models on the left. This list will be
   empty if there are no running models in your AWS account.
5. Click the "Open Image..." button and choose an image file.
6. Click "Detect Custom Labels".
7. Once the list of detected labels is populated on the right, you can select an
   item to highlight on the image.

## Content Moderation

![Rekognition Demo application detecting unsafe content in an image.](ContentModeration.png)

### Running the content moderation sample

1. Open "Rekognition Demos.groupproj" in Delphi or RAD Studio.
2. Activate the "ContentModerationDemo.exe" project.
3. Select "Run \> Run" from the menu or press F9.
4. Click the "Open Image..." button and choose an image.
5. Click "Detect Moderation Labels". If no content moderation labels are
   detected, the image will be revealed automatically.
6. When an image remains blurred, it means content moderation labels were
   detected. Inspect the detected moderation labels in the list on the left.
   If you wish to reveal the image, you can select the "Reveal" checkbox on the
   top-right.

## Required IAM permissions

- `rekognition:DetectLabels` (Label Detection)
- `rekognition:DetectCustomLabels` (Custom Label Detection)
- `rekognition:DetectModerationLabels` (Content Moderation)
