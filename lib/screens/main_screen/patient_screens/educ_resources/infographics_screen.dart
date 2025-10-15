import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdfx/pdfx.dart';
import 'educational_data_service.dart';

// PDF Thumbnail Widget
class PdfThumbnailWidget extends StatefulWidget {
  final String pdfPath;
  final double width;
  final double height;
  final Color? fallbackColor;
  final IconData? fallbackIcon;

  const PdfThumbnailWidget({
    super.key,
    required this.pdfPath,
    required this.width,
    required this.height,
    this.fallbackColor,
    this.fallbackIcon,
  });

  @override
  State<PdfThumbnailWidget> createState() => _PdfThumbnailWidgetState();
}

class _PdfThumbnailWidgetState extends State<PdfThumbnailWidget> {
  PdfController? _pdfController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      _pdfController = PdfController(
        document: PdfDocument.openAsset(widget.pdfPath),
      );

      // Wait a moment for the controller to initialize
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: widget.fallbackColor ?? Colors.grey.shade100,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
        ),
      );
    }

    if (_hasError || _pdfController == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: widget.fallbackColor ?? Colors.grey.shade100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              widget.fallbackIcon ?? FontAwesomeIcons.filePdf,
              size: 32,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 4),
            Text(
              'PDF Preview',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: PdfView(
          controller: _pdfController!,
          scrollDirection: Axis.vertical,
          physics:
              const NeverScrollableScrollPhysics(), // Disable scrolling in thumbnail
          onDocumentLoaded: (document) {
            // PDF loaded successfully
          },
          onPageChanged: (page) {
            // Handle page changes if needed
          },
        ),
      ),
    );
  }
}

class InfographicsScreen extends StatefulWidget {
  const InfographicsScreen({super.key});

  @override
  State<InfographicsScreen> createState() => _InfographicsScreenState();
}

class _InfographicsScreenState extends State<InfographicsScreen> {
  String selectedCategory = 'All';
  List<Map<String, dynamic>> allInfographics = [];
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    _loadInfographics();
  }

  void _loadInfographics() {
    allInfographics = EducationalDataService.getInfographicResources();
    categories = ['All'] + EducationalDataService.getInfographicCategories();
  }

  List<Map<String, dynamic>> get filteredInfographics {
    if (selectedCategory == 'All') {
      return allInfographics;
    }
    return allInfographics
        .where((infographic) => infographic['category'] == selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon:
                            Icon(Icons.arrow_back, color: Colors.grey.shade700),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Infographics & Resources',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: Text(
                      'Visual guides, PDFs, and educational materials about hemophilia',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Category filter
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue.shade700,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.blue.shade700
                            : Colors.grey.shade700,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.blue.shade300
                            : Colors.grey.shade300,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Infographics grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filteredInfographics.length,
                  itemBuilder: (context, index) {
                    final infographic = filteredInfographics[index];
                    return _buildInfographicCard(infographic);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfographicCard(Map<String, dynamic> infographic) {
    final IconData iconData = _getIconFromString(infographic['icon']);
    final bool isImage = infographic['type'] == 'image';
    final bool isPdf = infographic['type'] == 'pdf';

    return GestureDetector(
      onTap: () => _openInfographic(infographic),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail section
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  if (isImage)
                    // Image preview
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.asset(
                        infographic['path'],
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to icon if image fails to load
                          return Container(
                            width: double.infinity,
                            height: 120,
                            color: infographic['thumbnailColor'] ??
                                Colors.blue.shade100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  iconData,
                                  size: 32,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image Preview Unavailable',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  else if (isPdf)
                    // PDF preview
                    PdfThumbnailWidget(
                      pdfPath: infographic['path'],
                      width: double.infinity,
                      height: 120,
                      fallbackColor:
                          infographic['thumbnailColor'] ?? Colors.blue.shade100,
                      fallbackIcon: iconData,
                    )
                  else
                    // Other file types - icon display
                    Container(
                      width: double.infinity,
                      height: 120,
                      color:
                          infographic['thumbnailColor'] ?? Colors.blue.shade100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            iconData,
                            size: 32,
                            color: Colors.grey.shade700,
                          ),
                        ],
                      ),
                    ),

                  // Type badge positioned at top-right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTypeColor(infographic['type']),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        infographic['type'].toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      infographic['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        infographic['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.tag,
                          size: 10,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            infographic['category'],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red.shade600;
      case 'image':
        return Colors.green.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'file-medical':
        return FontAwesomeIcons.fileMedical;
      case 'calendar-check':
        return FontAwesomeIcons.calendarCheck;
      case 'heart':
        return FontAwesomeIcons.heart;
      case 'question-circle':
        return FontAwesomeIcons.circleQuestion;
      case 'exclamation-triangle':
        return FontAwesomeIcons.triangleExclamation;
      case 'first-aid':
        return FontAwesomeIcons.kitMedical;
      case 'robot':
        return FontAwesomeIcons.robot;
      default:
        return FontAwesomeIcons.file;
    }
  }

  void _openInfographic(Map<String, dynamic> infographic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InfographicViewerScreen(infographic: infographic),
      ),
    );
  }
}

class InfographicViewerScreen extends StatefulWidget {
  final Map<String, dynamic> infographic;

  const InfographicViewerScreen({super.key, required this.infographic});

  @override
  State<InfographicViewerScreen> createState() =>
      _InfographicViewerScreenState();
}

class _InfographicViewerScreenState extends State<InfographicViewerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.infographic['title'],
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 18),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.infographic['type'] == 'pdf'
                        ? 'Pinch to zoom • Swipe to navigate pages'
                        : 'Pinch to zoom • Pan to move around',
                  ),
                  backgroundColor: Colors.grey.shade800,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            widget.infographic['type'] == 'pdf'
                ? _buildPdfViewer()
                : _buildImageViewer(),

            // Zoom instruction overlay (shows briefly then fades)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: 0.0, // You can make this show initially and fade out
                duration: const Duration(seconds: 2),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade600, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        FontAwesomeIcons.handPointer,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.infographic['type'] == 'pdf'
                            ? 'Pinch to zoom • Swipe for pages'
                            : 'Pinch to zoom • Pan to explore',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return FutureBuilder<PdfDocument>(
      future: _loadPdfDocument(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Loading PDF...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  FontAwesomeIcons.triangleExclamation,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unable to load PDF',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${snapshot.error ?? "Unknown error"}',
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: PdfView(
            controller: PdfController(
              document: Future.value(snapshot.data!),
            ),
            onDocumentLoaded: (document) {
              print('PDF loaded with ${document.pagesCount} pages');
            },
            onPageChanged: (page) {
              print('Current page: $page');
            },
          ),
        );
      },
    );
  }

  Future<PdfDocument> _loadPdfDocument() async {
    try {
      final document = await PdfDocument.openAsset(widget.infographic['path']);
      return document;
    } catch (e) {
      throw Exception('Failed to load PDF: $e');
    }
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      clipBehavior: Clip.none,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Image.asset(
            widget.infographic['path'],
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      FontAwesomeIcons.triangleExclamation,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load image',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check if the file exists: ${widget.infographic['path']}',
                      style:
                          TextStyle(color: Colors.grey.shade300, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
