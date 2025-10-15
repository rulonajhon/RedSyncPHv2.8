# Infographics & Visual Resources Guide

## Overview
The RedSync app now includes a dedicated infographics section that displays PDF documents and images about hemophilia. This feature is accessible through the Educational Resources screen.

## Current Infographic Resources

### PDFs Available:
1. **Hemophilia A Disease State Infographic** - Comprehensive pathophysiology guide
2. **Long-Term Prophylaxis (LTP) Guide** - Healthcare professional treatment strategies  
3. **Hemophilia & Blood Donor Month** - ProACT awareness infographic
4. **What is Haemophilia? Visual Guide** - Basic explanation infographic

### Images Available:
1. **Most Common Symptoms** - Visual symptom reference guide
2. **RICE Method Guide** - Emergency bleeding management steps
3. **H.E.M.O Guidance Example** - Screenshot of app's H.E.M.O emergency feature

## File Locations
- **Assets Path**: `assets/pdf/`
- **Declared in**: `pubspec.yaml` under assets section
- **Code Implementation**: `lib/screens/main_screen/patient_screens/educ_resources/`

## Adding New Infographics

### Step 1: Add File to Assets
1. Place your PDF or image file in `assets/pdf/` folder
2. Supported formats: PDF, PNG, JPG, WEBP

### Step 2: Update pubspec.yaml
Ensure `assets/pdf/` is included in the assets section:
```yaml
assets:
  - assets/pdf/
```

### Step 3: Add Resource to Data Service
In `educational_data_service.dart`, add your new resource to the `getInfographicResources()` method:

```dart
{
  'id': 'your-resource-id',
  'title': 'Your Resource Title',
  'description': 'Brief description of what this resource contains',
  'type': 'pdf', // or 'image'
  'category': 'Understanding Hemophilia', // Choose existing or create new category
  'path': 'assets/pdf/your-file-name.pdf',
  'thumbnailColor': Colors.blue.shade100,
  'icon': 'file-medical', // FontAwesome icon name
},
```

### Available Categories:
- Understanding Hemophilia
- Treatment Options  
- Symptoms & Recognition
- Emergency Management
- Awareness & Support
- App Features

### Available Icons:
- `file-medical` - Medical documents
- `calendar-check` - Treatment schedules
- `heart` - Awareness/support materials
- `question-circle` - FAQ/basic info
- `exclamation-triangle` - Symptoms/warnings
- `first-aid` - Emergency procedures
- `robot` - App features

### Step 4: Test Implementation
1. Run `flutter pub get` if you added new assets
2. Build and test: `flutter build apk --debug`
3. Navigate to Educational Resources → Infographics & Visual Guides
4. Verify your resource appears and can be opened

## Features

### PDF Viewer Features:
- ✅ Native in-app PDF viewing with pdfx
- ✅ Zoom in/out with pinch gestures
- ✅ Swipe to navigate pages
- ✅ Full-screen viewing experience
- ✅ Loading states and error handling

### Image Viewer Features:
- ✅ Interactive zoom (0.5x to 4x)
- ✅ Pan and zoom gestures
- ✅ Error handling with helpful messages

### User Interface:
- ✅ Category filtering (All, Understanding Hemophilia, etc.)
- ✅ Grid layout with visual thumbnails
- ✅ Color-coded resource types (PDF=red, Image=green)
- ✅ Responsive design for mobile devices

## Technical Implementation

### Dependencies Used:
- `pdfx: ^2.7.0` - In-app PDF viewer with zoom and scroll
- `path_provider: ^2.1.5` - File system access  
- `path: ^1.9.0` - Path manipulation utilities

### Key Components:
1. **InfographicsScreen** - Main grid view of all resources
2. **InfographicViewerScreen** - Full-screen PDF/image viewer
3. **EducationalDataService** - Data management and resource definitions

### Asset Management:
- PDF files are copied to temporary directory for viewing
- Images are loaded directly from assets
- Error handling for missing or corrupted files

## Troubleshooting

### Common Issues:
1. **PDF won't load**: Check file path in `getInfographicResources()`
2. **Image shows error**: Verify file exists in `assets/pdf/` folder  
3. **App crashes**: Ensure `flutter pub get` was run after adding new assets
4. **Resource not appearing**: Check category name matches existing categories

### Debug Steps:
1. Verify file exists in `assets/pdf/`
2. Check `pubspec.yaml` includes `assets/pdf/`
3. Confirm resource is added to `getInfographicResources()`
4. Run `flutter clean` then `flutter pub get`
5. Rebuild app with `flutter build apk --debug`

## Future Enhancements

### Planned Features:
- [ ] Share functionality for resources
- [ ] Offline downloading capability
- [ ] Search/filter within infographics
- [ ] Bookmarking favorite resources
- [ ] Multi-language resource support

### Extensibility:
The system is designed to be easily extensible. New categories, resource types, and features can be added by updating the `EducationalDataService` class and corresponding UI components.