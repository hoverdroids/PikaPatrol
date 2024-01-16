import 'package:gsheets/gsheets.dart';
import 'package:pika_patrol/services/worksheet_service.dart';

class ObservationsWorksheetService extends WorksheetService {

  static const String OBSERVATIONS_WORKSHEET_TITLE = "Observations";

  ObservationsWorksheetService(
    Spreadsheet spreadsheet,
    bool doInitHeaderRow,
    {int columnHeadersRowNumber = WorksheetService.DEFAULT_COLUMN_HEADER_ROW_NUMBER}
  ) : super(
    spreadsheet,
    OBSERVATIONS_WORKSHEET_TITLE,
    [
      WorksheetService.UID_COLUMN_TITLE,
    ],
    doInitHeaderRow,
    columnHeadersRowNumber: columnHeadersRowNumber
  );
}