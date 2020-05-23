
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });

        let flight1 = "F1";
        let flight2 = "F2";
        let flight3 = "F3";
        let flight4 = "F4";
        contract.registerFlight(flight1, (error, result) => {
            console.log(error,result);
            display('Available flights', '', [ { label: 'Flight : ', error: error, value: result.flight },
            { label: 'time : ', error: error, value: result.timestamp } ]);
        });
        contract.registerFlight(flight2, (error, result) => {
            console.log(error,result);
            display('', '', [ { label: 'Flight : ', error: error, value: result.flight },
             { label: 'time : ', error: error, value: result.timestamp } ]);
        });        
        contract.registerFlight(flight3, (error, result) => {
            console.log(error,result);
            display('', '', [ { label: 'Flight : ', error: error, value: result.flight },
            { label: 'time : ', error: error, value: result.timestamp } ]);
        });        
        contract.registerFlight(flight4, (error, result) => {
            console.log(error,result);
            display('', '', [ { label: 'Flight : ', error: error, value: result.flight },
            { label: 'time : ', error: error, value: result.timestamp } ]);
        });
        
        DOM.elid('buyInsurance').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            let payment = DOM.elid('InsurancePayment').value;
            // Write transaction
            contract.buyInsurance(flight, payment, (error, result) => {
                console.log(error,result);
                display('bught insurance', '', [ { label: 'Flight ' + flight +' payment:', error: error, value: payment} ]);
            });
        })

        DOM.elid('getFounds').addEventListener('click', () => {

            // Write transaction
            contract.getCredit((error, result) => {
                console.log(error,result);
                display('Credit', '', [ { label: 'current credit : ', error: error, value: result} ]);
            });
        })

        DOM.elid('withdrawFounds').addEventListener('click', () => {

            // Write transaction
            contract.withdrawCredit((error, result) => {
                console.log(error,result);
                display('withdraw Credit', '', [ { label: 'status : ', error: error, value: "success"} ]);
            });
        })


        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', async () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            await contract.fetchFlightStatus(flight, (error, result) => {
                //display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });

            contract.getFlight(flight, (error, result) => {
                console.log(error,result);
                status = statusCode(result.statusCode);
                display('flight status', '', [ { label: 'Flight ' + flight +':', error: error, value: status } ]);
            });
        })
    
    });
    

})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}



function statusCode(code)
{
    switch(code) {
        case "0":
          return "STATUS_CODE_UNKNOWN";
          break;
          case "10":
          return "STATUS_CODE_ON_TIME";
          break;
          case "20":
          return "STATUS_CODE_LATE_AIRLINE";
          break;
          case "30":
          return "STATUS_CODE_LATE_WEATHER";
          break;
          case "40":
          return "STATUS_CODE_LATE_TECHNICAL";
          break;
          case "50":
          return "STATUS_CODE_LATE_OTHER";
          break;
        default:
          return "";
      } 
}








